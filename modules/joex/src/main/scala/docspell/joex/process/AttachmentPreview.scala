/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.Functor
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.extract.pdfbox.PdfboxPreview
import docspell.extract.pdfbox.PreviewConfig
import docspell.scheduler._
import docspell.store.Store
import docspell.store.queries.QAttachment
import docspell.store.records.RAttachment
import docspell.store.records._

/** Goes through all attachments that must be already converted into a pdf. If it is a
  * pdf, the first page is converted into a small preview png image and linked to the
  * attachment.
  */
object AttachmentPreview {

  def apply[F[_]: Sync](pcfg: PreviewConfig, store: Store[F])(
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"Creating preview images for ${item.attachments.size} files…"
        )
        preview <- PdfboxPreview(pcfg)
        _ <- item.attachments
          .traverse(createPreview(ctx, store, preview))
          .attempt
          .flatMap {
            case Right(_) => ().pure[F]
            case Left(ex) =>
              ctx.logger.error(ex)(
                s"Creating preview images failed, continuing without it."
              )
          }
      } yield item
    }

  def createPreview[F[_]: Sync](
      ctx: Context[F, _],
      store: Store[F],
      preview: PdfboxPreview[F]
  )(
      ra: RAttachment
  ): F[Option[RAttachmentPreview]] =
    findMime[F](store)(ra).flatMap {
      case MimeType.PdfMatch(_) =>
        preview.previewPNG(loadFile(store)(ra)).flatMap {
          case Some(out) =>
            ctx.logger.debug("Preview generated, saving to database…") *>
              createRecord(store, ra.fileId.collective, out, ra).map(_.some)
          case None =>
            ctx.logger
              .info(s"Preview could not be generated. Maybe the pdf has no pages?") *>
              (None: Option[RAttachmentPreview]).pure[F]
        }

      case mt =>
        ctx.logger.warn(s"Not a pdf file, but ${mt.asString}, cannot create preview.") *>
          (None: Option[RAttachmentPreview]).pure[F]
    }

  private def createRecord[F[_]: Sync](
      store: Store[F],
      collective: CollectiveId,
      png: Stream[F, Byte],
      ra: RAttachment
  ): F[RAttachmentPreview] = {
    val name = ra.name
      .map(FileName.apply)
      .map(_.withPart("preview", '_').withExtension("png"))
    for {
      fileId <- png
        .through(
          store.fileRepo.save(
            collective,
            FileCategory.PreviewImage,
            MimeTypeHint(name.map(_.fullName), Some("image/png"))
          )
        )
        .compile
        .lastOrError
      now <- Timestamp.current[F]
      rp = RAttachmentPreview(ra.id, fileId, name.map(_.fullName), now)
      _ <- QAttachment.deletePreview(store)(ra.id)
      _ <- store.transact(RAttachmentPreview.insert(rp))
    } yield rp
  }

  def findMime[F[_]: Functor](store: Store[F])(ra: RAttachment): F[MimeType] =
    OptionT(store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(MimeType.octetStream)

  def loadFile[F[_]](store: Store[F])(ra: RAttachment): Stream[F, Byte] =
    store.fileRepo.getBytes(ra.fileId)
}
