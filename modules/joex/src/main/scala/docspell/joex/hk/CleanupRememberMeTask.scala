/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records._

object CleanupRememberMeTask {
  def apply[F[_]: Sync](
      cfg: HouseKeepingConfig.CleanupRememberMe,
      store: Store[F]
  ): Task[F, Unit, CleanupResult] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup remember-me tokens older than $ts")
          n <- store.transact(RRememberMe.deleteOlderThan(ts))
          _ <- ctx.logger.info(s"Removed $n tokens")
        } yield CleanupResult.of(n)
      else
        ctx.logger.info("CleanupRememberMe task is disabled in the configuration") *>
          CleanupResult.disabled.pure[F]
    }
}
