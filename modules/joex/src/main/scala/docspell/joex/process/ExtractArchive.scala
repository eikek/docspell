package docspell.joex.process

import bitpeace.{Mimetype, MimetypeHint, RangeDef}
import cats.Functor
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream
import docspell.common._
import docspell.joex.mail._
import docspell.joex.scheduler._
import docspell.store.records._
import docspell.files.Zip
import cats.kernel.Monoid

/** Goes through all attachments and extracts archive files, like zip
  * files. The process is recursive, until all archives have been
  * extracted.
  *
  * The archive file is stored as a `attachment_archive` record that
  * references all its elements. If there are inner archive, only the
  * outer archive file is preserved.
  *
  * This step assumes an existing premature item, it traverses its
  * attachments.
  */
object ExtractArchive {

  def apply[F[_]: ConcurrentEffect: ContextShift](
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    multiPass(item, None).map(_._2)

  def multiPass[F[_]: ConcurrentEffect: ContextShift](
      item: ItemData,
      archive: Option[RAttachmentArchive]
  ): Task[F, ProcessItemArgs, (Option[RAttachmentArchive], ItemData)] =
    singlePass(item, archive).flatMap { t =>
      if (t._1 == None) Task.pure(t)
      else multiPass(t._2, t._1)
    }

  def singlePass[F[_]: ConcurrentEffect: ContextShift](
      item: ItemData,
      archive: Option[RAttachmentArchive]
  ): Task[F, ProcessItemArgs, (Option[RAttachmentArchive], ItemData)] =
    Task { ctx =>
      def extract(ra: RAttachment) =
        findMime(ctx)(ra).flatMap(m => extractSafe(ctx, archive)(ra, m))

      for {
        ras <- item.attachments.traverse(extract)
        nra = ras.flatMap(_.files).zipWithIndex.map(t => t._1.copy(position = t._2))
        _ <- nra.traverse(storeAttachment(ctx))
        naa = ras.flatMap(_.archives)
        _ <- naa.traverse(storeArchive(ctx))
      } yield naa.headOption -> item.copy(
        attachments = nra,
        originFile = item.originFile ++ nra.map(a => a.id -> a.fileId).toMap
      )
    }

  def findMime[F[_]: Functor](ctx: Context[F, _])(ra: RAttachment): F[Mimetype] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(Mimetype.`application/octet-stream`)

  def extractSafe[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, ProcessItemArgs],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment, mime: Mimetype): F[Extracted] =
    mime match {
      case Mimetype("application", "zip", _) if ra.name.exists(_.endsWith(".zip")) =>
        ctx.logger.info(s"Extracting zip archive ${ra.name.getOrElse("<noname>")}.") *>
          extractZip(ctx, archive)(ra)
            .flatTap(_ => cleanupParents(ctx, ra, archive))

      case Mimetype("message", "rfc822", _) =>
        ctx.logger.info(s"Reading e-mail ${ra.name.getOrElse("<noname>")}") *>
          extractMail(ctx, archive)(ra)
            .flatTap(_ => cleanupParents(ctx, ra, archive))

      case _ =>
        ctx.logger.debug(s"Not an archive: ${mime.asString}") *>
          Extracted.noArchive(ra).pure[F]
    }

  def cleanupParents[F[_]: Sync](
      ctx: Context[F, _],
      ra: RAttachment,
      archive: Option[RAttachmentArchive]
  ): F[Unit] =
    archive match {
      case Some(_) =>
        for {
          _ <- ctx.logger.debug(
            s"Extracted inner attachment ${ra.name}. Remove it completely."
          )
          _ <- ctx.store.transact(RAttachmentArchive.delete(ra.id))
          _ <- ctx.store.transact(RAttachment.delete(ra.id))
          _ <- ctx.store.bitpeace.delete(ra.fileId.id).compile.drain
        } yield ()
      case None =>
        for {
          _ <- ctx.logger.debug(
            s"Extracted attachment ${ra.name}. Remove it from the item."
          )
          _ <- ctx.store.transact(RAttachment.delete(ra.id))
        } yield ()
    }

  def extractZip[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, _],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment): F[Extracted] = {
    val zipData = ctx.store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))

    zipData
      .through(Zip.unzipP[F](8192, ctx.blocker))
      .flatMap(handleEntry(ctx, ra, archive))
      .foldMonoid
      .compile
      .lastOrError
  }

  def extractMail[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, _],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment): F[Extracted] = {
    val email = ctx.store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))

    email
      .through(ReadMail.readBytesP[F](ctx.logger))
      .flatMap(handleEntry(ctx, ra, archive))
      .foldMonoid
      .compile
      .lastOrError
  }

  def handleEntry[F[_]: Sync](
      ctx: Context[F, _],
      ra: RAttachment,
      archive: Option[RAttachmentArchive]
  )(
      entry: Binary[F]
  ): Stream[F, Extracted] = {
    val mimeHint = MimetypeHint.filename(entry.name).withAdvertised(entry.mime.asString)
    val fileMeta = ctx.store.bitpeace.saveNew(entry.data, 8192, mimeHint)
    Stream.eval(ctx.logger.debug(s"Extracted ${entry.name}. Storing as attachment.")) >>
      fileMeta.evalMap { fm =>
        Ident.randomId.map { id =>
          val nra = RAttachment(
            id,
            ra.itemId,
            Ident.unsafe(fm.id),
            0, //position is updated afterwards
            ra.created,
            Option(entry.name).map(_.trim).filter(_.nonEmpty)
          )
          val aa = archive.getOrElse(RAttachmentArchive.of(ra)).copy(id = id)
          Extracted.of(nra, aa)
        }
      }

  }

  def storeAttachment[F[_]: Sync](ctx: Context[F, _])(ra: RAttachment): F[Int] = {
    val insert = CreateItem.insertAttachment(ctx)(ra)
    for {
      n1 <- ctx.store.transact(RAttachment.updatePosition(ra.id, ra.position))
      n2 <- if (n1 > 0) 0.pure[F] else insert
    } yield n1 + n2
  }

  def storeArchive[F[_]: Sync](ctx: Context[F, _])(aa: RAttachmentArchive): F[Int] =
    ctx.store.transact(RAttachmentArchive.insert(aa))

  case class Extracted(files: Vector[RAttachment], archives: Vector[RAttachmentArchive]) {
    def ++(e: Extracted) =
      Extracted(files ++ e.files, archives ++ e.archives)
  }
  object Extracted {
    val empty = Extracted(Vector.empty, Vector.empty)

    def noArchive(ra: RAttachment): Extracted =
      Extracted(Vector(ra), Vector.empty)

    def of(ra: RAttachment, aa: RAttachmentArchive): Extracted =
      Extracted(Vector(ra), Vector(aa))

    implicit val extractedMonoid: Monoid[Extracted] =
      Monoid.instance(empty, _ ++ _)
  }

}
