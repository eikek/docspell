package docspell.joex.process

import bitpeace.{Mimetype, MimetypeHint, RangeDef}
import cats.implicits._
import cats.Functor
import cats.implicits._
import cats.effect._
import cats.data.{Kleisli, OptionT}
import fs2.Stream
import docspell.common._
import docspell.convert._
import docspell.joex.scheduler._
import docspell.store.records._
import docspell.convert.ConversionResult.Handler

/** Goes through all attachments and creates a PDF version of it where
  * supported.
  *
  * The `attachment` record is updated with the PDF version while the
  * original file has been stored in the `attachment_source` record.
  *
  * If pdf conversion is not possible or if the input is already a
  * pdf, both files are identical. That is, the `file_id`s point to
  * the same file. Since the name of an attachment may be changed by
  * the user, the `attachment_origin` record keeps that, too.
  *
  * This step assumes an existing premature item, it traverses its
  * attachments.
  */
object ConvertPdf {

  def apply[F[_]: Sync: ContextShift](
      cfg: ConvertConfig,
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      def convert(ra: RAttachment) =
        findMime(ctx)(ra).flatMap(m => convertSafe(cfg, ctx, item)(ra, m))

      for {
        ras <- item.attachments.traverse(convert)
        nra = ras.map(_._1)
        nma = ras.flatMap(_._2)
      } yield item.copy(attachments = nra, metas = nma)

    }

  def findMime[F[_]: Functor](ctx: Context[F, _])(ra: RAttachment): F[Mimetype] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(Mimetype.`application/octet-stream`)

  def convertSafe[F[_]: Sync: ContextShift](
      cfg: ConvertConfig,
      ctx: Context[F, ProcessItemArgs],
      item: ItemData
  )(ra: RAttachment, mime: Mimetype): F[(RAttachment, Option[RAttachmentMeta])] =
    Conversion.create[F](cfg, ctx.blocker, ctx.logger).use { conv =>
      mime match {
        case mt if mt.baseEqual(Mimetype.`application/pdf`) =>
          ctx.logger.info("Not going to convert a PDF file into a PDF.") *>
            (ra, None: Option[RAttachmentMeta]).pure[F]

        case _ =>
          val data = ctx.store.bitpeace
            .get(ra.fileId.id)
            .unNoneTerminate
            .through(ctx.store.bitpeace.fetchData2(RangeDef.all))
          val mt      = MimeType(mime.primary, mime.sub, mime.params)
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
    Kleisli({
      case ConversionResult.SuccessPdf(pdf) =>
        ctx.logger.info(s"Conversion to pdf successful. Saving file.") *>
          storePDF(ctx, cfg, ra, pdf)
            .map(r => (r, None))

      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        ctx.logger.info(s"Conversion to pdf+txt successful. Saving file.") *>
          storePDF(ctx, cfg, ra, pdf)
            .flatMap(r =>
              txt.map(t => (r, item.changeMeta(ra.id, _.setContentIfEmpty(t.some)).some))
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
    })

  private def storePDF[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs],
      cfg: ConvertConfig,
      ra: RAttachment,
      pdf: Stream[F, Byte]
  ) = {
    val hint =
      MimeTypeHint.advertised(MimeType.pdf).withName(ra.name.getOrElse("file.pdf"))
    val newName = ra.name.map(n => s"$n.pdf")
    ctx.store.bitpeace
      .saveNew(pdf, cfg.chunkSize, MimetypeHint(hint.filename, hint.advertised))
      .compile
      .lastOrError
      .map(fm => Ident.unsafe(fm.id))
      .flatMap(fmId =>
        ctx.store
          .transact(RAttachment.updateFileIdAndName(ra.id, fmId, newName))
          .map(_ => fmId)
      )
      .map(fmId => ra.copy(fileId = fmId, name = newName))
  }
}
