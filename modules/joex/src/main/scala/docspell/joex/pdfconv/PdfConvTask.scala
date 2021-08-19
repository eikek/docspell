/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.pdfconv

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.extern.OcrMyPdf
import docspell.joex.Config
import docspell.joex.scheduler.{Context, Task}
import docspell.store.records._

import bitpeace.FileMeta
import bitpeace.Mimetype
import bitpeace.MimetypeHint
import bitpeace.RangeDef
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

  val taskName = Ident.unsafe("pdf-files-migration")

  def apply[F[_]: Async](cfg: Config): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _    <- ctx.logger.info(s"Converting pdf file ${ctx.args} using ocrmypdf")
        meta <- checkInputs(cfg, ctx)
        _    <- meta.traverse(fm => convert(cfg, ctx, fm))
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling pdfconv task"))

  // --- Helper

  // check if file exists and if it is pdf and if source id is the same and if ocrmypdf is enabled
  def checkInputs[F[_]: Sync](cfg: Config, ctx: Context[F, Args]): F[Option[FileMeta]] = {
    val none: Option[FileMeta] = None
    val checkSameFiles =
      (for {
        ra <- OptionT(ctx.store.transact(RAttachment.findById(ctx.args.attachId)))
        isSame <- OptionT.liftF(
          ctx.store.transact(RAttachmentSource.isSameFile(ra.id, ra.fileId))
        )
      } yield isSame).getOrElse(false)
    val existsPdf =
      for {
        meta <- ctx.store.transact(RAttachment.findMeta(ctx.args.attachId))
        res = meta.filter(_.mimetype.matches(Mimetype.applicationPdf))
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

  def convert[F[_]: Async](
      cfg: Config,
      ctx: Context[F, Args],
      in: FileMeta
  ): F[Unit] = {
    val bp = ctx.store.bitpeace
    val data = Stream
      .emit(in)
      .through(bp.fetchData2(RangeDef.all))

    val storeResult: ConversionResult.Handler[F, Unit] =
      Kleisli {
        case ConversionResult.SuccessPdf(file) =>
          storeToAttachment(ctx, in, file)

        case ConversionResult.SuccessPdfTxt(file, _) =>
          storeToAttachment(ctx, in, file)

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
        in.chunksize,
        ctx.logger
      )(data, storeResult)

    for {
      lang <- getLanguage(ctx)
      _    <- ocrMyPdf(lang)
    } yield ()
  }

  def getLanguage[F[_]: Sync](ctx: Context[F, Args]): F[Language] =
    (for {
      coll <- OptionT(ctx.store.transact(RCollective.findByAttachment(ctx.args.attachId)))
      lang = coll.language
    } yield lang).getOrElse(Language.German)

  def storeToAttachment[F[_]: Sync](
      ctx: Context[F, Args],
      meta: FileMeta,
      newFile: Stream[F, Byte]
  ): F[Unit] = {
    val mimeHint = MimetypeHint.advertised(meta.mimetype.asString)
    for {
      time <- Timestamp.current[F]
      fid  <- Ident.randomId[F]
      _ <-
        ctx.store.bitpeace
          .saveNew(newFile, meta.chunksize, mimeHint, Some(fid.id), time.value)
          .compile
          .lastOrError
      _ <- ctx.store.transact(RAttachment.updateFileId(ctx.args.attachId, fid))
    } yield ()
  }

}
