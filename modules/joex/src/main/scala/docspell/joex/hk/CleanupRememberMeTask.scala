package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records._

object CleanupRememberMeTask {

  def apply[F[_]: Sync](cfg: HouseKeepingConfig.CleanupRememberMe): Task[F, Unit, Unit] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          now <- Timestamp.current[F]
          ts = now - cfg.olderThan
          _ <- ctx.logger.info(s"Cleanup remember-me tokens older than $ts")
          n <- ctx.store.transact(RRememberMe.deleteOlderThan(ts))
          _ <- ctx.logger.info(s"Removed $n tokens")
        } yield ()
      else
        ctx.logger.info("CleanupRememberMe task is disabled in the configuration")
    }
}
