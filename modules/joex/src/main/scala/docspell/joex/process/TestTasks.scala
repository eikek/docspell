package docspell.joex.process

import cats.implicits._
import cats.effect.Sync
import docspell.common.ProcessItemArgs
import docspell.common.syntax.all._
import docspell.joex.scheduler.Task
import org.log4s._

object TestTasks {
  private[this] val logger = getLogger

  def success[F[_]]: Task[F, ProcessItemArgs, Unit] =
    Task(ctx => ctx.logger.info(s"Running task now: ${ctx.args}"))

  def failing[F[_]: Sync]: Task[F, ProcessItemArgs, Unit] =
    Task { ctx =>
      ctx.logger
        .info(s"Failing the task run :(")
        .map(_ => sys.error("Oh, cannot extract gold from this document"))
    }

  def longRunning[F[_]: Sync]: Task[F, ProcessItemArgs, Unit] =
    Task { ctx =>
      logger.fwarn(s"${Thread.currentThread()} From executing long running task") >>
        ctx.logger.info(s"${Thread.currentThread()} Running task now: ${ctx.args}") >>
        sleep(2400) >>
        ctx.logger.debug("doing things") >>
        sleep(2400) >>
        ctx.logger.debug("doing more things") >>
        sleep(2400) >>
        ctx.logger.info("doing more things")
    }

  private def sleep[F[_]: Sync](ms: Long): F[Unit] =
    Sync[F].delay(Thread.sleep(ms))
}
