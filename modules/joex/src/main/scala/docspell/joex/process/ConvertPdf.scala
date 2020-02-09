package docspell.joex.process

import bitpeace.Mimetype
import cats.Functor
import cats.implicits._
import cats.effect._
import cats.data.OptionT

import docspell.common._
import docspell.joex.scheduler._
import docspell.store.records._

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
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>

      // get mimetype
      //   try to convert
      //   save to db
      //   update file_id of RAttachment

      def convert(ra: RAttachment) =
        findMime(ctx)(ra).flatMap(m => convertSafe(ctx)(ra, m))

      for {
        ras <- item.attachments.traverse(convert)
      } yield item.copy(attachments = ras)

    }

  def findMime[F[_]: Functor](ctx: Context[F, ProcessItemArgs])(ra: RAttachment): F[Mimetype] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(Mimetype.`application/octet-stream`)

  def convertSafe[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs]
  )(ra: RAttachment, mime: Mimetype): F[RAttachment] = {

    ctx.logger.info(s"File ${ra.name} has mime ${mime.asString}").
      map(_ => ra)
  }
}
