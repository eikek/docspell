/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.pdfconv

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream
import fs2.io.file.Files

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.extern.OcrMyPdf
import docspell.joex.Config
import docspell.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.records._

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Converts the given attachment file using ocrmypdf if it is a pdf and has not already
  * been converted (the source file is the same as in the attachment).
  */
object PdfConvTask {
  case class Args(attachId: Ident)
  object Args {
    implicit val jsonDecoder: Decoder[Args] =
      deriveDecoder[Args]
    implicit val jsonEncoder: Encoder[Args] =
      deriveEncoder[Args]
  }

  val taskName: Ident = Ident.unsafe("pdf-files-migration")

  def apply[F[_]: Async: Files](cfg: Config, store: Store[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(s"Converting pdf file ${ctx.args} using ocrmypdf")
        meta <- checkInputs(cfg, ctx, store)
        _ <- meta.traverse(fm => convert(cfg, ctx, store, fm))
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling pdfconv task"))

  // --- Helper

  // check if file exists and if it is pdf and if source id is the same and if ocrmypdf is enabled
  def checkInputs[F[_]: Sync](
      cfg: Config,
      ctx: Context[F, Args],
      store: Store[F]
  ): F[Option[RFileMeta]] = {
    val none: Option[RFileMeta] = None
    val checkSameFiles =
      (for {
        ra <- OptionT(store.transact(RAttachment.findById(ctx.args.attachId)))
        isSame <- OptionT.liftF(
          store.transact(RAttachmentSource.isSameFile(ra.id, ra.fileId))
        )
      } yield isSame).getOrElse(false)
    val existsPdf =
      for {
        meta <- store.transact(RAttachment.findMeta(ctx.args.attachId))
        res = meta.filter(_.mimetype.matches(MimeType.pdf))
        _ <-
          if (res.isEmpty)
            ctx.logger.info(
              s"The attachment ${ctx.args.attachId} doesn't exist or is no pdf: $meta"
            )
          else ().pure[F]
      } yield res

    if (cfg.convert.ocrmypdf.enabled)
      checkSameFiles.flatMap {
        case true => existsPdf
        case false =>
          ctx.logger.info(
            s"The attachment ${ctx.args.attachId} already has been converted. Skipping."
          ) *>
            none.pure[F]
      }
    else none.pure[F]
  }

  def convert[F[_]: Async: Files](
      cfg: Config,
      ctx: Context[F, Args],
      store: Store[F],
      in: RFileMeta
  ): F[Unit] = {
    val fs = store.fileRepo
    val data = fs.getBytes(in.id)

    val storeResult: ConversionResult.Handler[F, Unit] =
      Kleisli {
        case ConversionResult.SuccessPdf(file) =>
          storeToAttachment(ctx, store, in, file)

        case ConversionResult.SuccessPdfTxt(file, _) =>
          storeToAttachment(ctx, store, in, file)

        case ConversionResult.UnsupportedFormat(mime) =>
          ctx.logger.warn(
            s"Unable to convert '$mime' file ${ctx.args}: unsupported format."
          )

        case ConversionResult.InputMalformed(mime, reason) =>
          ctx.logger.warn(s"Unable to convert '$mime' file ${ctx.args}: $reason")

        case ConversionResult.Failure(ex) =>
          Sync[F].raiseError(ex)
      }

    def ocrMyPdf(lang: Language): F[Unit] =
      OcrMyPdf.toPDF[F, Unit](
        cfg.convert.ocrmypdf,
        lang,
        cfg.files.chunkSize,
        ctx.logger
      )(data, storeResult)

    for {
      lang <- getLanguage(ctx, store)
      _ <- ocrMyPdf(lang)
    } yield ()
  }

  def getLanguage[F[_]: Sync](ctx: Context[F, Args], store: Store[F]): F[Language] =
    (for {
      coll <- OptionT(store.transact(RCollective.findByAttachment(ctx.args.attachId)))
      lang = coll.language
    } yield lang).getOrElse(Language.German)

  def storeToAttachment[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      meta: RFileMeta,
      newFile: Stream[F, Byte]
  ): F[Unit] = {
    val mimeHint = MimeTypeHint.advertised(meta.mimetype)
    val collective = meta.id.collective
    val cat = FileCategory.AttachmentConvert
    for {
      fid <-
        newFile
          .through(store.fileRepo.save(collective, cat, mimeHint))
          .compile
          .lastOrError
      _ <- store.transact(RAttachment.updateFileId(ctx.args.attachId, fid))
    } yield ()
  }
}
