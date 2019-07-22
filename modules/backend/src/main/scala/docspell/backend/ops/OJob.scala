package docspell.backend.ops

import cats.implicits._
import cats.effect.{ConcurrentEffect, Resource}
import docspell.backend.ops.OJob.{CollectiveQueueState, JobCancelResult}
import docspell.common.{Ident, JobState}
import docspell.store.Store
import docspell.store.queries.QJob
import docspell.store.records.{RJob, RJobLog}

import scala.concurrent.ExecutionContext

trait OJob[F[_]] {

  def queueState(collective: Ident, maxResults: Int): F[CollectiveQueueState]

  def cancelJob(id: Ident, collective: Ident): F[JobCancelResult]
}

object OJob {

  sealed trait JobCancelResult
  object JobCancelResult {
    case object Removed extends JobCancelResult
    case object CancelRequested extends JobCancelResult
    case object JobNotFound extends JobCancelResult
  }

  case class JobDetail(job: RJob, logs: Vector[RJobLog])
  case class CollectiveQueueState(jobs: Vector[JobDetail]) {
    def queued: Vector[JobDetail] =
      jobs.filter(r => JobState.queued.contains(r.job.state))
    def done: Vector[JobDetail] =
      jobs.filter(r => JobState.done.contains(r.job.state))
    def running: Vector[JobDetail] =
      jobs.filter(_.job.state == JobState.Running)
  }

  def apply[F[_]: ConcurrentEffect](store: Store[F], clientEC: ExecutionContext): Resource[F, OJob[F]] =
    Resource.pure(new OJob[F] {

      def queueState(collective: Ident, maxResults: Int): F[CollectiveQueueState] = {
        store.transact(QJob.queueStateSnapshot(collective).take(maxResults.toLong)).
          map(t => JobDetail(t._1, t._2)).
          compile.toVector.
          map(CollectiveQueueState)
      }

      def cancelJob(id: Ident, collective: Ident): F[JobCancelResult] = {
        def mustCancel(job: Option[RJob]): Option[(RJob, Ident)] =
          for {
            worker <- job.flatMap(_.worker)
            job    <- job.filter(j => j.state == JobState.Scheduled || j.state == JobState.Running)
          } yield (job, worker)

        def canDelete(j: RJob): Boolean =
          mustCancel(j.some).isEmpty

        val tryDelete = for {
          job  <- RJob.findByIdAndGroup(id, collective)
          jobm  = job.filter(canDelete)
          del  <- jobm.traverse(j => RJob.delete(j.id))
        } yield del match {
          case Some(n) => Right(JobCancelResult.Removed: JobCancelResult)
          case None => Left(mustCancel(job))
        }

        def tryCancel(job: RJob, worker: Ident): F[JobCancelResult] =
          OJoex.cancelJob(job.id, worker, store, clientEC).
            map(flag => if (flag) JobCancelResult.CancelRequested else JobCancelResult.JobNotFound)

        for {
          tryDel  <- store.transact(tryDelete)
          result  <- tryDel  match {
            case Right(r) => r.pure[F]
            case Left(Some((job, worker))) =>
              tryCancel(job, worker)
            case Left(None) =>
              (JobCancelResult.JobNotFound: OJob.JobCancelResult).pure[F]
          }
        } yield result
      }
    })
}
