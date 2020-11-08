package docspell.joex.preview

import cats.implicits._
import cats.effect._
import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachmentPreview
import docspell.joex.scheduler.Context
import docspell.joex.process.AttachmentPreview
import docspell.convert.ConvertConfig
import docspell.extract.pdfbox.PdfboxPreview
import docspell.store.records.RAttachment

object MakePreviewTask {

  type Args = MakePreviewArgs

  def apply[F[_]: Sync](cfg: ConvertConfig): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        exists  <- previewExists(ctx)
        preview <- PdfboxPreview(30)
        _ <-
          if (exists)
            ctx.logger.info(
              s"Preview already exists for attachment ${ctx.args.attachment}. Skipping."
            )
          else
            ctx.logger.info(
              s"Generating preview image for attachment ${ctx.args.attachment}"
            ) *> generatePreview(ctx, preview, cfg)
      } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling make-preview task"))

  private def generatePreview[F[_]: Sync](
      ctx: Context[F, Args],
      preview: PdfboxPreview[F],
      cfg: ConvertConfig
  ): F[Unit] =
    for {
      ra <- ctx.store.transact(RAttachment.findById(ctx.args.attachment))
      _ <- ra
        .map(AttachmentPreview.createPreview(ctx, preview, cfg.chunkSize))
        .getOrElse(().pure[F])
    } yield ()

  private def previewExists[F[_]: Sync](ctx: Context[F, Args]): F[Boolean] =
    if (ctx.args.store == MakePreviewArgs.StoreMode.WhenMissing)
      ctx.store.transact(
        RAttachmentPreview.findById(ctx.args.attachment).map(_.isDefined)
      )
    else
      false.pure[F]
}
