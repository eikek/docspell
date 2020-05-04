package docspell.joex.hk

import cats.implicits._
import cats.effect._

import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records._

object CleanupInvitesTask {

  def apply[F[_]: Sync](cfg: HouseKeepingConfig.CleanupInvites): Task[F, Unit, Unit] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup invitations older than $ts")
          n <- ctx.store.transact(RInvitation.deleteOlderThan(ts))
          _ <- ctx.logger.info(s"Removed $n invitations")
        } yield ()
      else
        ctx.logger.info("CleanupInvites task is disabled in the configuration")
    }
}
