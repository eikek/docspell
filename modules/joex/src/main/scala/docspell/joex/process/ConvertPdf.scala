/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.Functor
import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.convert.SanitizeHtml
import docspell.convert._
import docspell.joex.extract.JsoupSanitizer
import docspell.joex.scheduler._
import docspell.store.records._

/** Goes through all attachments and creates a PDF version of it where supported.
  *
  * The `attachment` record is updated with the PDF version while the original file has
  * been stored in the `attachment_source` record.
  *
  * If pdf conversion is not possible or if the input is already a pdf, both files are
  * identical. That is, the `file_id`s point to the same file. Since the name of an
  * attachment may be changed by the user, the `attachment_origin` record keeps that, too.
  *
  * This step assumes an existing premature item, it traverses its attachments.
  */
object ConvertPdf {

  def apply[F[_]: Async](
      cfg: ConvertConfig,
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      def convert(ra: RAttachment): F[(RAttachment, Option[RAttachmentMeta])] =
        isConverted(ctx)(ra).flatMap {
          case true if ctx.args.isNormalProcessing =>
            ctx.logger.info(
              s"Conversion to pdf already done for attachment ${ra.name}."
            ) *>
              ctx.store
                .transact(RAttachmentMeta.findById(ra.id))
                .map(rmOpt => (ra, rmOpt))
          case _ =>
            findMime(ctx)(ra).flatMap(m =>
              convertSafe(cfg, JsoupSanitizer.clean, ctx, item)(ra, m)
            )
        }

      for {
        ras <- item.attachments.traverse(convert)
        nra = ras.map(_._1)
        nma = ras.flatMap(_._2)
      } yield item.copy(attachments = nra, metas = nma)

    }

  def isConverted[F[_]](ctx: Context[F, ProcessItemArgs])(
      ra: RAttachment
  ): F[Boolean] =
    ctx.store.transact(RAttachmentSource.isConverted(ra.id))

  def findMime[F[_]: Functor](ctx: Context[F, _])(ra: RAttachment): F[MimeType] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(MimeType.octetStream)

  def convertSafe[F[_]: Async](
      cfg: ConvertConfig,
      sanitizeHtml: SanitizeHtml,
      ctx: Context[F, ProcessItemArgs],
      item: ItemData
  )(ra: RAttachment, mime: MimeType): F[(RAttachment, Option[RAttachmentMeta])] =
    Conversion.create[F](cfg, sanitizeHtml, ctx.logger).use { conv =>
      mime match {
        case mt =>
          val data    = ctx.store.fileStore.getBytes(ra.fileId)
          val handler = conversionHandler[F](ctx, cfg, ra, item)
          ctx.logger.info(s"Converting file ${ra.name} (${mime.asString}) into a PDF") *>
            conv.toPDF(DataType(mt), ctx.args.meta.language, handler)(
              data
            )
      }
    }

  private def conversionHandler[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs],
      cfg: ConvertConfig,
      ra: RAttachment,
      item: ItemData
  ): Handler[F, (RAttachment, Option[RAttachmentMeta])] =
    Kleisli {
      case ConversionResult.SuccessPdf(pdf) =>
        ctx.logger.info(s"Conversion to pdf successful. Saving file.") *>
          storePDF(ctx, cfg, ra, pdf)
            .map(r => (r, None))

      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        ctx.logger.info(s"Conversion to pdf+txt successful. Saving file.") *>
          storePDF(ctx, cfg, ra, pdf)
            .flatMap(r =>
              txt.map(t =>
                (
                  r,
                  item
                    .changeMeta(
                      ra.id,
                      ctx.args.meta.language,
                      _.setContentIfEmpty(t.some)
                    )
                    .some
                )
              )
            )

      case ConversionResult.UnsupportedFormat(mt) =>
        ctx.logger.info(s"PDF conversion for type ${mt.asString} not supported!") *>
          (ra, None: Option[RAttachmentMeta]).pure[F]

      case ConversionResult.InputMalformed(mt, reason) =>
        ctx.logger.info(
          s"PDF conversion from type ${mt.asString} reported malformed input: $reason."
        ) *>
          (ra, None: Option[RAttachmentMeta]).pure[F]

      case ConversionResult.Failure(ex) =>
        ctx.logger
          .error(s"PDF conversion failed: ${ex.getMessage}. Go without PDF file") *>
          (ra, None: Option[RAttachmentMeta]).pure[F]
    }

  private def storePDF[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs],
      cfg: ConvertConfig,
      ra: RAttachment,
      pdf: Stream[F, Byte]
  ) = {
    val hint =
      MimeTypeHint.advertised(MimeType.pdf).withName(ra.name.getOrElse("file.pdf"))
    val newName =
      ra.name
        .map(FileName.apply)
        .map(_.withExtension("pdf").withPart(cfg.convertedFilenamePart, '.'))
        .map(_.fullName)

    pdf
      .through(ctx.store.fileStore.save(MimeTypeHint(hint.filename, hint.advertised)))
      .compile
      .lastOrError
      .flatMap(fmId => updateAttachment[F](ctx, ra, fmId, newName).map(_ => fmId))
      .map(fmId => ra.copy(fileId = fmId, name = newName))
  }

  private def updateAttachment[F[_]: Sync](
      ctx: Context[F, _],
      ra: RAttachment,
      fmId: Ident,
      newName: Option[String]
  ): F[Unit] =
    for {
      oldFile <- ctx.store.transact(RAttachment.findById(ra.id))
      _ <-
        ctx.store
          .transact(RAttachment.updateFileIdAndName(ra.id, fmId, newName))
      _ <- oldFile match {
        case Some(raPrev) =>
          for {
            sameFile <-
              ctx.store
                .transact(RAttachmentSource.isSameFile(ra.id, raPrev.fileId))
            _ <-
              if (sameFile) ().pure[F]
              else
                ctx.logger.info("Deleting previous attachment file") *>
                  ctx.store.fileStore
                    .delete(raPrev.fileId)
                    .attempt
                    .flatMap {
                      case Right(_) => ().pure[F]
                      case Left(ex) =>
                        ctx.logger
                          .error(ex)(s"Cannot delete previous attachment file: $raPrev")

                    }
          } yield ()
        case None =>
          ().pure[F]
      }
    } yield ()
}
