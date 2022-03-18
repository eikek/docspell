/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.Store
import docspell.store.records.RJob

trait JobQueue[F[_]] {
  def nextJob(
      prio: Ident => F[Priority],
      worker: Ident,
      retryPause: Duration
  ): F[Option[RJob]]
}

object JobQueue {
  private[scheduler] def apply[F[_]: Async](store: Store[F]): JobQueue[F] =
    new JobQueue[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def nextJob(
          prio: Ident => F[Priority],
          worker: Ident,
          retryPause: Duration
      ): F[Option[RJob]] =
        logger
          .trace("Select next job") *> QJob.takeNextJob(store)(prio, worker, retryPause)
    }
}
