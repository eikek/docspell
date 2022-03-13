/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records._

object CleanupJobsTask {

  def apply[F[_]: Sync](
      cfg: HouseKeepingConfig.CleanupJobs,
      store: Store[F]
  ): Task[F, Unit, CleanupResult] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup jobs older than $ts")
          n <- deleteDoneJobs(store, ts, cfg.deleteBatch)
          _ <- ctx.logger.info(s"Removed $n jobs")
        } yield CleanupResult.of(n)
      else
        ctx.logger.info("CleanupJobs task is disabled in the configuration") *>
          CleanupResult.disabled.pure[F]
    }

  def deleteDoneJobs[F[_]: Sync](store: Store[F], ts: Timestamp, batch: Int): F[Int] =
    Stream
      .eval(store.transact(RJob.deleteDoneAndOlderThan(ts, batch)))
      .repeat
      .takeWhile(_ > 0)
      .compile
      .foldMonoid
}
