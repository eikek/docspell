/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OJob.{CollectiveQueueState, JobCancelResult}
import docspell.common.Priority
import docspell.common.{Ident, JobState}
import docspell.store.Store
import docspell.store.UpdateResult
import docspell.store.queries.QJob
import docspell.store.records.{RJob, RJobLog}

trait OJob[F[_]] {

  def queueState(collective: Ident, maxResults: Int): F[CollectiveQueueState]

  def cancelJob(id: Ident, collective: Ident): F[JobCancelResult]

  def setPriority(id: Ident, collective: Ident, prio: Priority): F[UpdateResult]
}

object OJob {

  sealed trait JobCancelResult
  object JobCancelResult {
    case object Removed extends JobCancelResult
    case object CancelRequested extends JobCancelResult
    case object JobNotFound extends JobCancelResult

    def removed: JobCancelResult = Removed
    def cancelRequested: JobCancelResult = CancelRequested
    def jobNotFound: JobCancelResult = JobNotFound
  }

  case class JobDetail(job: RJob, logs: Vector[RJobLog])
  case class CollectiveQueueState(jobs: Vector[JobDetail]) {
    def queued: Vector[JobDetail] =
      jobs.filter(r => JobState.queued.contains(r.job.state))
    def done: Vector[JobDetail] =
      jobs.filter(r => JobState.done.toList.contains(r.job.state))
    def running: Vector[JobDetail] =
      jobs.filter(_.job.state == JobState.Running)
  }

  def apply[F[_]: Sync](
      store: Store[F],
      joex: OJoex[F]
  ): Resource[F, OJob[F]] =
    Resource.pure[F, OJob[F]](new OJob[F] {

      def queueState(collective: Ident, maxResults: Int): F[CollectiveQueueState] =
        store
          .transact(
            QJob.queueStateSnapshot(collective, maxResults.toLong)
          )
          .map(t => JobDetail(t._1, t._2))
          .compile
          .toVector
          .map(CollectiveQueueState)

      def setPriority(id: Ident, collective: Ident, prio: Priority): F[UpdateResult] =
        UpdateResult.fromUpdate(store.transact(RJob.setPriority(id, collective, prio)))

      def cancelJob(id: Ident, collective: Ident): F[JobCancelResult] = {
        def remove(job: RJob): F[JobCancelResult] =
          store.transact(RJob.delete(job.id)) *> JobCancelResult.removed.pure[F]

        def tryCancel(job: RJob): F[JobCancelResult] =
          job.worker match {
            case Some(worker) =>
              for {
                flag <- joex.cancelJob(job.id, worker)
                res <-
                  if (flag) JobCancelResult.cancelRequested.pure[F]
                  else remove(job)
              } yield res
            case None =>
              remove(job)
          }

        (for {
          job <- OptionT(store.transact(RJob.findByIdAndGroup(id, collective)))
          result <- OptionT.liftF(
            if (job.isInProgress) tryCancel(job)
            else remove(job)
          )
        } yield result)
          .getOrElse(JobCancelResult.jobNotFound)
      }
    })
}
