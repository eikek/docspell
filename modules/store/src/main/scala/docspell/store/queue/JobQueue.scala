/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queue

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.Store
import docspell.store.queries.QJob
import docspell.store.records.RJob

import org.log4s.getLogger

trait JobQueue[F[_]] {

  /** Inserts the job into the queue to get picked up as soon as possible. The job must
    * have a new unique id.
    */
  def insert(job: RJob): F[Unit]

  /** Inserts the job into the queue only, if there is no job with the same tracker-id
    * running at the moment. The job id must be a new unique id.
    *
    * If the job has no tracker defined, it is simply inserted.
    */
  def insertIfNew(job: RJob): F[Boolean]

  def insertAll(jobs: Seq[RJob]): F[Int]

  def insertAllIfNew(jobs: Seq[RJob]): F[Int]

  def nextJob(
      prio: Ident => F[Priority],
      worker: Ident,
      retryPause: Duration
  ): F[Option[RJob]]
}

object JobQueue {
  def apply[F[_]: Async](store: Store[F]): Resource[F, JobQueue[F]] =
    Resource.pure[F, JobQueue[F]](new JobQueue[F] {
      private[this] val logger = Logger.log4s(getLogger)

      def nextJob(
          prio: Ident => F[Priority],
          worker: Ident,
          retryPause: Duration
      ): F[Option[RJob]] =
        logger
          .trace("Select next job") *> QJob.takeNextJob(store)(prio, worker, retryPause)

      def insert(job: RJob): F[Unit] =
        store
          .transact(RJob.insert(job))
          .flatMap { n =>
            if (n != 1)
              Async[F]
                .raiseError(new Exception(s"Inserting job failed. Update count: $n"))
            else ().pure[F]
          }

      def insertIfNew(job: RJob): F[Boolean] =
        for {
          rj <- job.tracker match {
            case Some(tid) =>
              store.transact(RJob.findNonFinalByTracker(tid))
            case None =>
              None.pure[F]
          }
          ret <-
            if (rj.isDefined) false.pure[F]
            else insert(job).as(true)
        } yield ret

      def insertAll(jobs: Seq[RJob]): F[Int] =
        jobs.toList
          .traverse(j => insert(j).attempt)
          .flatMap(_.traverse {
            case Right(()) => 1.pure[F]
            case Left(ex) =>
              logger.error(ex)("Could not insert job. Skipping it.").as(0)

          })
          .map(_.sum)

      def insertAllIfNew(jobs: Seq[RJob]): F[Int] =
        jobs.toList
          .traverse(j => insertIfNew(j).attempt)
          .flatMap(_.traverse {
            case Right(true)  => 1.pure[F]
            case Right(false) => 0.pure[F]
            case Left(ex) =>
              logger.error(ex)("Could not insert job. Skipping it.").as(0)
          })
          .map(_.sum)
    })
}
