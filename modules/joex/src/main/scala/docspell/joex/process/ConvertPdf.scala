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
import fs2.io.file.Files

import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.convert.SanitizeHtml
import docspell.convert._
import docspell.joex.extract.JsoupSanitizer
import docspell.scheduler._
import docspell.store.Store
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
  type Args = ProcessItemArgs

  def apply[F[_]: Async: Files](
      cfg: ConvertConfig,
      store: Store[F],
      item: ItemData
  ): Task[F, Args, ItemData] =
    Task { ctx =>
      def convert(ra: RAttachment): F[(RAttachment, Option[RAttachmentMeta])] =
        isConverted(store)(ra).flatMap {
          case true if ctx.args.isNormalProcessing =>
            ctx.logger.info(
              s"Conversion to pdf already done for attachment ${ra.name}."
            ) *>
              store
                .transact(RAttachmentMeta.findById(ra.id))
                .map(rmOpt => (ra, rmOpt))
          case _ =>
            findMime(store)(ra).flatMap(m =>
              convertSafe(cfg, JsoupSanitizer.clean, ctx, store, item)(ra, m)
            )
        }

      for {
        ras <- item.attachments.traverse(convert)
        nra = ras.map(_._1)
        nma = ras.flatMap(_._2)
      } yield item.copy(attachments = nra, metas = nma)

    }

  def isConverted[F[_]](store: Store[F])(
      ra: RAttachment
  ): F[Boolean] =
    store.transact(RAttachmentSource.isConverted(ra.id))

  def findMime[F[_]: Functor](store: Store[F])(
      ra: RAttachment
  ): F[MimeType] =
    OptionT(store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(MimeType.octetStream)

  def convertSafe[F[_]: Async: Files](
      cfg: ConvertConfig,
      sanitizeHtml: SanitizeHtml,
      ctx: Context[F, Args],
      store: Store[F],
      item: ItemData
  )(ra: RAttachment, mime: MimeType): F[(RAttachment, Option[RAttachmentMeta])] =
    loadCollectivePasswords(ctx, store).flatMap(collPass =>
      Conversion.create[F](cfg, sanitizeHtml, collPass, ctx.logger).use { conv =>
        mime match {
          case mt =>
            val data = store.fileRepo.getBytes(ra.fileId)
            val handler = conversionHandler[F](ctx, store, cfg, ra, item)
            ctx.logger
              .info(s"Converting file ${ra.name} (${mime.asString}) into a PDF") *>
              conv.toPDF(DataType(mt), ctx.args.meta.language, handler)(
                data
              )
        }
      }
    )

  private def loadCollectivePasswords[F[_]: Async](
      ctx: Context[F, Args],
      store: Store[F]
  ): F[List[Password]] =
    store
      .transact(RCollectivePassword.findAll(ctx.args.meta.collective))
      .map(_.map(_.password).distinct)

  private def conversionHandler[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: ConvertConfig,
      ra: RAttachment,
      item: ItemData
  ): Handler[F, (RAttachment, Option[RAttachmentMeta])] =
    Kleisli {
      case ConversionResult.SuccessPdf(pdf) =>
        ctx.logger.info(s"Conversion to pdf successful. Saving file.") *>
          storePDF(ctx, store, cfg, ra, pdf)
            .map(r => (r, None))

      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        ctx.logger.info(s"Conversion to pdf+txt successful. Saving file.") *>
          storePDF(ctx, store, cfg, ra, pdf)
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
      ctx: Context[F, Args],
      store: Store[F],
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
      .through(
        store.fileRepo.save(
          ctx.args.meta.collective,
          FileCategory.AttachmentConvert,
          MimeTypeHint(hint.filename, hint.advertised)
        )
      )
      .compile
      .lastOrError
      .flatMap(fmId => updateAttachment[F](ctx, store, ra, fmId, newName).map(_ => fmId))
      .map(fmId => ra.copy(fileId = fmId, name = newName))
  }

  private def updateAttachment[F[_]: Sync](
      ctx: Context[F, _],
      store: Store[F],
      ra: RAttachment,
      fmId: FileKey,
      newName: Option[String]
  ): F[Unit] =
    for {
      oldFile <- store.transact(RAttachment.findById(ra.id))
      _ <-
        store
          .transact(RAttachment.updateFileIdAndName(ra.id, fmId, newName))
      _ <- oldFile match {
        case Some(raPrev) =>
          for {
            sameFile <-
              store
                .transact(RAttachmentSource.isSameFile(ra.id, raPrev.fileId))
            _ <-
              if (sameFile) ().pure[F]
              else
                ctx.logger.info("Deleting previous attachment file") *>
                  store.fileRepo
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
