/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.preview

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.extract.pdfbox.PdfboxPreview
import docspell.extract.pdfbox.PreviewConfig
import docspell.joex.process.AttachmentPreview
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachment
import docspell.store.records.RAttachmentPreview

object MakePreviewTask {

  type Args = MakePreviewArgs

  def apply[F[_]: Sync](pcfg: PreviewConfig): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        exists <- previewExists(ctx)
        preview <- PdfboxPreview(pcfg)
        _ <-
          if (exists)
            ctx.logger.info(
              s"Preview already exists for attachment ${ctx.args.attachment}. Skipping."
            )
          else
            ctx.logger.info(
              s"Generating preview image for attachment ${ctx.args.attachment}"
            ) *> generatePreview(ctx, preview)
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling make-preview task"))

  private def generatePreview[F[_]: Sync](
      ctx: Context[F, Args],
      preview: PdfboxPreview[F]
  ): F[Unit] =
    for {
      ra <- ctx.store.transact(RAttachment.findById(ctx.args.attachment))
      _ <- ra
        .map(AttachmentPreview.createPreview(ctx, preview))
        .getOrElse(
          ctx.logger.error(s"No attachment found with id: ${ctx.args.attachment}")
        )
    } yield ()

  private def previewExists[F[_]: Sync](ctx: Context[F, Args]): F[Boolean] =
    if (ctx.args.store == MakePreviewArgs.StoreMode.WhenMissing)
      ctx.store.transact(
        RAttachmentPreview.findById(ctx.args.attachment).map(_.isDefined)
      )
    else
      false.pure[F]
}
