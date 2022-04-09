/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.syntax.all._

import docspell.backend.ops.ODownloadAll
import docspell.common._
import docspell.scheduler._

object CleanupDownloadsTask {
  def apply[F[_]: Sync](
      cfg: HouseKeepingConfig.CleanupDownloads,
      ops: ODownloadAll[F]
  ): Task[F, Unit, CleanupResult] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup downloads older than $ts")
          n <- ops.deleteOlderThan(ts)
          _ <- ctx.logger.info(s"Removed $n download archives")
        } yield CleanupResult.of(n)
      else
        ctx.logger.info("CleanupDownloads task is disabled in the configuration") *>
          CleanupResult.disabled.pure[F]
    }
}
