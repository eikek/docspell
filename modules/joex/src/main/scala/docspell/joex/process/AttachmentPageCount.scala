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
            ctx.logger.debug(s"Found number of pages: ${md.pageCount}") *>
              updatePageCount(ctx, md, ra).map(_.some)
          case Left(ex) =>
            ctx.logger.warn(s"Error obtaining pages count: ${ex.getMessage}") *>
              (None: Option[PdfMetaData]).pure[F]
        }

      case mt =>
        ctx.logger.warn(s"Not a pdf file, but ${mt.asString}, cannot get page count.") *>
          (None: Option[PdfMetaData]).pure[F]
    }

  private def updatePageCount[F[_]: Sync](
      ctx: Context[F, _],
      md: PdfMetaData,
      ra: RAttachment
  ): F[PdfMetaData] =
    for {
      _ <- ctx.logger.debug(
        s"Update attachment ${ra.id.id} with page count ${md.pageCount.some}"
      )
      n <- ctx.store.transact(RAttachmentMeta.updatePageCount(ra.id, md.pageCount.some))
      m <-
        if (n == 0)
          ctx.logger.warn(
            s"No attachmentmeta record exists for ${ra.id.id}. Creating new."
          ) *> ctx.store.transact(
            RAttachmentMeta.insert(
              RAttachmentMeta(ra.id, None, Nil, MetaProposalList.empty, md.pageCount.some)
            )
          )
        else 0.pure[F]
      _ <- ctx.logger.debug(s"Stored page count (${n + m}).")
    } yield md

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
