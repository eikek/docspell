/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import cats.implicits._

import docspell.backend.JobFactory
import docspell.common._
import docspell.scheduler.JobStore
import docspell.store.Store
import docspell.store.records.RJob

trait OFulltext[F[_]] {

  /** Clears the full-text index completely and launches a task that indexes all data. */
  def reindexAll: F[Unit]

  /** Clears the full-text index for the given collective and starts a task indexing all
    * their data.
    */
  def reindexCollective(cid: CollectiveId, submitterUserId: Option[Ident]): F[Unit]
}

object OFulltext {
  def apply[F[_]: Async](
      store: Store[F],
      jobStore: JobStore[F]
  ): Resource[F, OFulltext[F]] =
    Resource.pure[F, OFulltext[F]](new OFulltext[F] {
      val logger = docspell.logging.getLogger[F]
      def reindexAll: F[Unit] =
        for {
          _ <- logger.info(s"Re-index all.")
          job <- JobFactory.reIndexAll[F]
          _ <- jobStore.insertIfNew(job.encode)
        } yield ()

      def reindexCollective(cid: CollectiveId, submitterUserId: Option[Ident]): F[Unit] =
        for {
          _ <- logger.debug(s"Re-index collective: $cid")
          exist <- store.transact(
            RJob.findNonFinalByTracker(DocspellSystem.migrationTaskTracker)
          )
          job <- JobFactory.reIndex(cid, submitterUserId)
          _ <-
            if (exist.isDefined) ().pure[F]
            else jobStore.insertIfNew(job.encode)
        } yield ()
    })
}
