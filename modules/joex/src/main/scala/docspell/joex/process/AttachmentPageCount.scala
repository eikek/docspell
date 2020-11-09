package docspell.joex.process

import cats.Functor
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.extract.pdfbox.PdfMetaData
import docspell.extract.pdfbox.PdfboxExtract
import docspell.joex.scheduler._
import docspell.store.records.RAttachment
import docspell.store.records._
import docspell.store.syntax.MimeTypes._

import bitpeace.{Mimetype, RangeDef}

/** Goes through all attachments that must be already converted into a
  * pdf. If it is a pdf, the number of pages are retrieved and stored
  * in the attachment metadata.
  */
object AttachmentPageCount {

  def apply[F[_]: Sync: ContextShift]()(
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"Retrieving page count for ${item.attachments.size} files…"
        )
        _ <- item.attachments
          .traverse(createPageCount(ctx))
          .attempt
          .flatMap {
            case Right(_) => ().pure[F]
            case Left(ex) =>
              ctx.logger.error(ex)(
                s"Retrieving page counts failed, continuing without it."
              )
          }
      } yield item
    }

  def createPageCount[F[_]: Sync](
      ctx: Context[F, _]
  )(ra: RAttachment): F[Option[PdfMetaData]] =
    findMime[F](ctx)(ra).flatMap {
      case MimeType.PdfMatch(_) =>
        PdfboxExtract.getMetaData(loadFile(ctx)(ra)).flatMap {
          case Right(md) =>
            updatePageCount(ctx, md, ra).map(_.some)
          case Left(ex) =>
            ctx.logger.warn(s"Error obtaining pages count: ${ex.getMessage}") *>
              (None: Option[PdfMetaData]).pure[F]
        }

      case _ =>
        (None: Option[PdfMetaData]).pure[F]
    }

  private def updatePageCount[F[_]: Sync](
      ctx: Context[F, _],
      md: PdfMetaData,
      ra: RAttachment
  ): F[PdfMetaData] =
    ctx.store.transact(RAttachmentMeta.updatePageCount(ra.id, md.pageCount.some)) *> md
      .pure[F]

  def findMime[F[_]: Functor](ctx: Context[F, _])(ra: RAttachment): F[MimeType] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(Mimetype.`application/octet-stream`)
      .map(_.toLocal)

  def loadFile[F[_]](ctx: Context[F, _])(ra: RAttachment): Stream[F, Byte] =
    ctx.store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))

}
