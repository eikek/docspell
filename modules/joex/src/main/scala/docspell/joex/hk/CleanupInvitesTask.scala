/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records._

object CleanupInvitesTask {

  def apply[F[_]: Sync](
      cfg: HouseKeepingConfig.CleanupInvites
  ): Task[F, Unit, CleanupResult] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup invitations older than $ts")
          n <- ctx.store.transact(RInvitation.deleteOlderThan(ts))
          _ <- ctx.logger.info(s"Removed $n invitations")
        } yield CleanupResult.of(n)
      else
        ctx.logger.info("CleanupInvites task is disabled in the configuration") *>
          CleanupResult.disabled.pure[F]
    }
}
