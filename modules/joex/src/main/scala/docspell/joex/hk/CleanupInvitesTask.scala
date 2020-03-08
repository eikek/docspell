package docspell.joex.hk

import cats.implicits._
import cats.effect._

import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.records._

object CleanupInvitesTask {

  def apply[F[_]: Sync: ContextShift](cfg: Config): Task[F, Unit, Unit] =
    Task { ctx =>
      val threshold = cfg.houseKeeping.cleanupInvites.olderThan
      for {
        now <- Timestamp.current[F]
        ts = now - threshold
        _   <- ctx.logger.info(s"Cleanup invitations older than $ts")
        n   <- ctx.store.transact(RInvitation.deleteOlderThan(ts))
        _   <- ctx.logger.info(s"Removed $n invitations")
      } yield ()
    }
}
