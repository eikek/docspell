package docspell.joex.process

import cats.Functor
import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import cats.kernel.Monoid
import cats.kernel.Order
import fs2.Stream

import docspell.common._
import docspell.files.Zip
import docspell.joex.mail._
import docspell.joex.scheduler._
import docspell.store.records._
import docspell.store.syntax.MimeTypes._

import bitpeace.{Mimetype, MimetypeHint, RangeDef}
import emil.Mail

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
      def extract(ra: RAttachment, pos: Int): F[Extracted] =
        findMime(ctx)(ra).flatMap(m => extractSafe(ctx, archive)(ra, pos, m))

      for {
        lastPos <- ctx.store.transact(RAttachment.nextPosition(item.item.id))
        extracts <-
          item.attachments.zipWithIndex
            .traverse(t => extract(t._1, lastPos + t._2))
            .map(Monoid[Extracted].combineAll)
            .map(fixPositions)
        nra = extracts.files
        _ <- extracts.files.traverse(storeAttachment(ctx))
        naa = extracts.archives
        _ <- naa.traverse(storeArchive(ctx))
      } yield naa.headOption -> item.copy(
        attachments = nra,
        originFile = item.originFile ++ nra.map(a => a.id -> a.fileId).toMap,
        givenMeta = item.givenMeta.fillEmptyFrom(extracts.meta)
      )
    }

  /** After all files have been extracted, the `extract' contains the
    * whole (combined) result. This fixes positions of the attachments
    * such that the elements of an archive are "spliced" into the
    * attachment list at the position of the archive. If there is no
    * archive, positions don't need to be fixed.
    */
  private def fixPositions(extract: Extracted): Extracted =
    if (extract.archives.isEmpty) extract
    else extract.updatePositions

  def findMime[F[_]: Functor](ctx: Context[F, _])(ra: RAttachment): F[Mimetype] =
    OptionT(ctx.store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(Mimetype.`application/octet-stream`)

  def extractSafe[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, ProcessItemArgs],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment, pos: Int, mime: Mimetype): F[Extracted] =
    mime.toLocal match {
      case MimeType.ZipMatch(_) if ra.name.exists(_.endsWith(".zip")) =>
        ctx.logger.info(s"Extracting zip archive ${ra.name.getOrElse("<noname>")}.") *>
          extractZip(ctx, archive)(ra, pos)
            .flatMap(cleanupParents(ctx, ra, archive))

      case MimeType.EmailMatch(_) =>
        ctx.logger.info(s"Reading e-mail ${ra.name.getOrElse("<noname>")}") *>
          extractMail(ctx, archive)(ra, pos)
            .flatMap(cleanupParents(ctx, ra, archive))

      case _ =>
        ctx.logger.debug(s"Not an archive: ${mime.asString}") *>
          Extracted.noArchive(ra, pos, 0).pure[F]
    }

  def cleanupParents[F[_]: Sync](
      ctx: Context[F, _],
      ra: RAttachment,
      archive: Option[RAttachmentArchive]
  )(extracted: Extracted): F[Extracted] =
    archive match {
      case Some(_) =>
        for {
          _ <- ctx.logger.debug(
            s"Extracted inner attachment ${ra.name}. Remove it completely."
          )
          _ <- ctx.store.transact(RAttachmentArchive.delete(ra.id))
          _ <- ctx.store.transact(RAttachment.delete(ra.id))
          _ <- ctx.store.bitpeace.delete(ra.fileId.id).compile.drain
        } yield extracted
      case None =>
        for {
          _ <- ctx.logger.debug(
            s"Extracted attachment ${ra.name}. Remove it from the item."
          )
          _ <- ctx.store.transact(RAttachment.delete(ra.id))
        } yield extracted.copy(files = extracted.files.filter(_.id != ra.id))
    }

  def extractZip[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, ProcessItemArgs],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment, pos: Int): F[Extracted] = {
    val zipData = ctx.store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))
    val glob = ctx.args.meta.fileFilter.getOrElse(Glob.all)
    ctx.logger.debug(s"Filtering zip entries with '${glob.asString}'") *>
      zipData
        .through(Zip.unzipP[F](8192, ctx.blocker, glob))
        .zipWithIndex
        .flatMap(handleEntry(ctx, ra, pos, archive, None))
        .foldMonoid
        .compile
        .lastOrError
  }

  def extractMail[F[_]: ConcurrentEffect: ContextShift](
      ctx: Context[F, ProcessItemArgs],
      archive: Option[RAttachmentArchive]
  )(ra: RAttachment, pos: Int): F[Extracted] = {
    val email: Stream[F, Byte] = ctx.store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))

    val glob = ctx.args.meta.fileFilter.getOrElse(Glob.all)
    ctx.logger.debug(s"Filtering email attachments with '${glob.asString}'") *>
      email
        .through(ReadMail.bytesToMail[F](ctx.logger))
        .flatMap { mail =>
          val mId = mail.header.messageId
          val givenMeta =
            for {
              _ <- ctx.logger.debug(s"Use mail date for item date: ${mail.header.date}")
              s <- Sync[F].delay(extractMailMeta(mail))
            } yield s

          ReadMail
            .mailToEntries(ctx.logger, glob)(mail)
            .zipWithIndex
            .flatMap(handleEntry(ctx, ra, pos, archive, mId)) ++ Stream.eval(givenMeta)
        }
        .foldMonoid
        .compile
        .lastOrError
  }

  def extractMailMeta[F[_]](mail: Mail[F]): Extracted =
    mail.header.date
      .map(Timestamp.apply)
      .map(ts => Extracted.empty.setMeta(MetaProposal.docDate(ts, None)))
      .getOrElse(Extracted.empty)

  def handleEntry[F[_]: Sync](
      ctx: Context[F, _],
      ra: RAttachment,
      pos: Int,
      archive: Option[RAttachmentArchive],
      messageId: Option[String]
  )(
      tentry: (Binary[F], Long)
  ): Stream[F, Extracted] = {
    val (entry, subPos) = tentry
    val mimeHint        = MimetypeHint.filename(entry.name).withAdvertised(entry.mime.asString)
    val fileMeta        = ctx.store.bitpeace.saveNew(entry.data, 8192, mimeHint)
    Stream.eval(ctx.logger.debug(s"Extracted ${entry.name}. Storing as attachment.")) >>
      fileMeta.evalMap { fm =>
        Ident.randomId.map { id =>
          val nra = RAttachment(
            id,
            ra.itemId,
            Ident.unsafe(fm.id),
            pos,
            ra.created,
            Option(entry.name).map(_.trim).filter(_.nonEmpty)
          )
          val aa = archive.getOrElse(RAttachmentArchive.of(ra, messageId)).copy(id = id)
          Extracted.of(nra, aa, pos, subPos.toInt)
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

  case class Extracted(
      files: Vector[RAttachment],
      archives: Vector[RAttachmentArchive],
      meta: MetaProposalList,
      positions: List[Extracted.Pos]
  ) {
    def ++(e: Extracted) =
      Extracted(
        files ++ e.files,
        archives ++ e.archives,
        meta.fillEmptyFrom(e.meta),
        positions ++ e.positions
      )

    def filterNames(filter: Glob): Extracted =
      copy(files =
        files.filter(ra => filter.matches(caseSensitive = false)(ra.name.getOrElse("")))
      )

    def setMeta(m: MetaProposal): Extracted =
      setMeta(MetaProposalList.of(m))

    def setMeta(ml: MetaProposalList): Extracted =
      Extracted(files, archives, meta.fillEmptyFrom(ml), positions)

    def updatePositions: Extracted =
      NonEmptyList.fromList(positions) match {
        case None =>
          this
        case Some(nel) =>
          val sorted = nel.sorted
          val offset = sorted.head.first
          val pos =
            sorted.zipWithIndex.map({ case (p, i) => p.id -> (i + offset) }).toList.toMap
          val nf =
            files.map(f => pos.get(f.id).map(n => f.copy(position = n)).getOrElse(f))
          copy(files = nf)
      }
  }
  object Extracted {
    val empty =
      Extracted(Vector.empty, Vector.empty, MetaProposalList.empty, Nil)

    def noArchive(ra: RAttachment, pos: Int, subPos: Int): Extracted =
      Extracted(
        Vector(ra),
        Vector.empty,
        MetaProposalList.empty,
        List(Pos(ra.id, pos, subPos))
      )

    def of(ra: RAttachment, aa: RAttachmentArchive, pos: Int, subPos: Int): Extracted =
      Extracted(
        Vector(ra),
        Vector(aa),
        MetaProposalList.empty,
        List(Pos(ra.id, pos, subPos))
      )

    implicit val extractedMonoid: Monoid[Extracted] =
      Monoid.instance(empty, _ ++ _)

    case class Pos(id: Ident, first: Int, second: Int)

    object Pos {
      implicit val ordering: Order[Pos] =
        Order.whenEqual(Order.by(_.first), Order.by(_.second))
    }
  }

}
