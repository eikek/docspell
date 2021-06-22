package docspell.store.queue

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.queries.QJob
import docspell.store.records.RJob

import org.log4s._

trait JobQueue[F[_]] {

  /** Inserts the job into the queue to get picked up as soon as
    * possible. The job must have a new unique id.
    */
  def insert(job: RJob): F[Unit]

  /** Inserts the job into the queue only, if there is no job with the
    * same tracker-id running at the moment. The job id must be a new
    * unique id.
    *
    * If the job has no tracker defined, it is simply inserted.
    */
  def insertIfNew(job: RJob): F[Unit]

  def insertAll(jobs: Seq[RJob]): F[Unit]

  def insertAllIfNew(jobs: Seq[RJob]): F[Unit]

  def nextJob(
      prio: Ident => F[Priority],
      worker: Ident,
      retryPause: Duration
  ): F[Option[RJob]]
}

object JobQueue {
  private[this] val logger = getLogger

  def apply[F[_]: Async](store: Store[F]): Resource[F, JobQueue[F]] =
    Resource.pure[F, JobQueue[F]](new JobQueue[F] {

      def nextJob(
          prio: Ident => F[Priority],
          worker: Ident,
          retryPause: Duration
      ): F[Option[RJob]] =
        logger
          .ftrace("Select next job") *> QJob.takeNextJob(store)(prio, worker, retryPause)

      def insert(job: RJob): F[Unit] =
        store
          .transact(RJob.insert(job))
          .flatMap { n =>
            if (n != 1)
              Async[F]
                .raiseError(new Exception(s"Inserting job failed. Update count: $n"))
            else ().pure[F]
          }

      def insertIfNew(job: RJob): F[Unit] =
        for {
          rj <- job.tracker match {
            case Some(tid) =>
              store.transact(RJob.findNonFinalByTracker(tid))
            case None =>
              None.pure[F]
          }
          ret <-
            if (rj.isDefined) ().pure[F]
            else insert(job)
        } yield ret

      def insertAll(jobs: Seq[RJob]): F[Unit] =
        jobs.toList
          .traverse(j => insert(j).attempt)
          .map(_.foreach {
            case Right(()) =>
            case Left(ex) =>
              logger.error(ex)("Could not insert job. Skipping it.")
          })

      def insertAllIfNew(jobs: Seq[RJob]): F[Unit] =
        jobs.toList
          .traverse(j => insertIfNew(j).attempt)
          .map(_.foreach {
            case Right(()) =>
            case Left(ex) =>
              logger.error(ex)("Could not insert job. Skipping it.")
          })
    })
}
