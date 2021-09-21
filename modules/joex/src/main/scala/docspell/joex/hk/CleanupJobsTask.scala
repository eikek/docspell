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
import docspell.joex.scheduler.Task
import docspell.store.Store
import docspell.store.records._

object CleanupJobsTask {

  def apply[F[_]: Sync](cfg: HouseKeepingConfig.CleanupJobs): Task[F, Unit, Unit] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup jobs older than $ts")
          n <- deleteDoneJobs(ctx.store, ts, cfg.deleteBatch)
          _ <- ctx.logger.info(s"Removed $n jobs")
        } yield ()
      else
        ctx.logger.info("CleanupJobs task is disabled in the configuration")
    }

  def deleteDoneJobs[F[_]: Sync](store: Store[F], ts: Timestamp, batch: Int): F[Int] =
    Stream
      .eval(store.transact(RJob.deleteDoneAndOlderThan(ts, batch)))
      .repeat
      .takeWhile(_ > 0)
      .compile
      .foldMonoid
}
