package docspell.joex.pagecount

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.joex.process.AttachmentPageCount
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachment
import docspell.store.records.RAttachmentMeta

object MakePageCountTask {

  type Args = MakePageCountArgs

  def apply[F[_]: Sync](): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        exists <- pageCountExists(ctx)
        _ <-
          if (exists)
            ctx.logger.info(
              s"PageCount already exists for attachment ${ctx.args.attachment}. Skipping."
            )
          else
            ctx.logger.info(
              s"Reading page-count for attachment ${ctx.args.attachment}"
            ) *> generatePageCount(ctx)
      } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling make-page-count task"))

  private def generatePageCount[F[_]: Sync](
      ctx: Context[F, Args]
  ): F[Unit] =
    for {
      ra <- ctx.store.transact(RAttachment.findById(ctx.args.attachment))
      _ <- ra
        .map(AttachmentPageCount.createPageCount(ctx))
        .getOrElse(
          ctx.logger.warn(s"No attachment found with id: ${ctx.args.attachment}")
        )
    } yield ()

  private def pageCountExists[F[_]: Sync](ctx: Context[F, Args]): F[Boolean] =
    ctx.store.transact(
      RAttachmentMeta
        .findPageCountById(ctx.args.attachment)
        .map(_.exists(_ > 0))
    )

}
