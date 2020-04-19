package docspell.joex.hk

import cats.implicits._
import cats.effect._

import docspell.common._
import docspell.joex.scheduler.Task

object NotifyDueItemsTask {

  def apply[F[_]: Sync](): Task[F, NotifyDueItemsArgs, Unit] =
    Task { ctx =>
        for {
          now <- Timestamp.current[F]
          _ <- ctx.logger.info(s" $now")
          _ <- ctx.logger.info(s"Removed $ctx")
        } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, NotifyDueItemsArgs, Unit] =
    Task.log(_.warn("Cancelling notify-due-items task"))

}
