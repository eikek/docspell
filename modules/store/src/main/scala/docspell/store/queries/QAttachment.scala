package docspell.store.queries

import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._

object QAttachment {
  private[this] val logger = org.log4s.getLogger

  private val a    = RAttachment.as("a")
  private val item = RItem.as("i")
  private val am   = RAttachmentMeta.as("am")
  private val c    = RCollective.as("c")

  def deletePreview[F[_]: Sync](store: Store[F])(attachId: Ident): F[Int] = {
    val findPreview =
      for {
        rp <- RAttachmentPreview.findById(attachId)
      } yield rp.toSeq

    Stream
      .evalSeq(store.transact(findPreview))
      .map(_.fileId.id)
      .evalTap(_ => store.transact(RAttachmentPreview.delete(attachId)))
      .flatMap(store.bitpeace.delete)
      .map(flag => if (flag) 1 else 0)
      .compile
      .foldMonoid
  }

  /** Deletes an attachment, its related source and meta data records.
    * It will only delete an related archive file, if this is the last
    * attachment in that archive.
    */
  def deleteSingleAttachment[F[_]: Sync](
      store: Store[F]
  )(attachId: Ident, coll: Ident): F[Int] = {
    val loadFiles = for {
      ra <- RAttachment.findByIdAndCollective(attachId, coll).map(_.map(_.fileId))
      rs <- RAttachmentSource.findByIdAndCollective(attachId, coll).map(_.map(_.fileId))
      rp <- RAttachmentPreview.findByIdAndCollective(attachId, coll).map(_.map(_.fileId))
      ne <- RAttachmentArchive.countEntries(attachId)
    } yield (ra.toSeq ++ rs.toSeq ++ rp.toSeq, ne)

    for {
      files <- store.transact(loadFiles)
      k <-
        if (files._2 == 1) deleteArchive(store)(attachId)
        else store.transact(RAttachmentArchive.delete(attachId))
      n <- store.transact(RAttachment.delete(attachId))
      f <-
        Stream
          .emits(files._1)
          .map(_.id)
          .flatMap(store.bitpeace.delete)
          .map(flag => if (flag) 1 else 0)
          .compile
          .foldMonoid
    } yield n + k + f
  }

  /** This deletes the attachment and *all* its related files. This used
    * when deleting an item and should not be used to delete a
    * *single* attachment where the item should stay.
    */
  private def deleteAttachment[F[_]: Sync](store: Store[F])(ra: RAttachment): F[Int] =
    for {
      _ <- logger.fdebug[F](s"Deleting attachment: ${ra.id.id}")
      s <- store.transact(RAttachmentSource.findById(ra.id))
      p <- store.transact(RAttachmentPreview.findById(ra.id))
      n <- store.transact(RAttachment.delete(ra.id))
      _ <- logger.fdebug[F](
        s"Deleted $n meta records (source, meta, preview, archive). Deleting binaries now."
      )
      f <-
        Stream
          .emits(ra.fileId.id +: (s.map(_.fileId.id).toSeq ++ p.map(_.fileId.id).toSeq))
          .flatMap(store.bitpeace.delete)
          .map(flag => if (flag) 1 else 0)
          .compile
          .foldMonoid
    } yield n + f

  def deleteArchive[F[_]: Sync](store: Store[F])(attachId: Ident): F[Int] =
    (for {
      aa <- OptionT(store.transact(RAttachmentArchive.findById(attachId)))
      n  <- OptionT.liftF(store.transact(RAttachmentArchive.deleteAll(aa.fileId)))
      _ <- OptionT.liftF(
        Stream
          .emit(aa.fileId.id)
          .flatMap(store.bitpeace.delete)
          .compile
          .drain
      )
    } yield n).getOrElse(0)

  def deleteItemAttachments[F[_]: Sync](
      store: Store[F]
  )(itemId: Ident, coll: Ident): F[Int] =
    for {
      ras <- store.transact(RAttachment.findByItemAndCollective(itemId, coll))
      _ <- logger.finfo[F](
        s"Have ${ras.size} attachments to delete. Must first delete archive entries"
      )
      a  <- ras.traverse(a => deleteArchive(store)(a.id))
      _  <- logger.fdebug[F](s"Deleted ${a.sum} archive entries")
      ns <- ras.traverse(deleteAttachment[F](store))
    } yield ns.sum

  def getMetaProposals(itemId: Ident, coll: Ident): ConnectionIO[MetaProposalList] = {
    val q = Select(
      am.proposals.s,
      from(am)
        .innerJoin(a, a.id === am.id)
        .innerJoin(item, a.itemId === item.id),
      a.itemId === itemId && item.cid === coll
    ).build

    for {
      ml <- q.query[MetaProposalList].to[Vector]
    } yield MetaProposalList.flatten(ml)
  }

  def getAttachmentMeta(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentMeta]] = {
    val q = Select(
      select(am.all),
      from(item)
        .innerJoin(a, a.itemId === item.id)
        .innerJoin(am, am.id === a.id),
      a.id === attachId && item.cid === collective
    ).build

    q.query[RAttachmentMeta].option
  }

  case class ContentAndName(
      id: Ident,
      item: Ident,
      collective: Ident,
      folder: Option[Ident],
      lang: Language,
      name: Option[String],
      content: Option[String]
  )
  def allAttachmentMetaAndName(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, ContentAndName] =
    Select(
      select(
        a.id.s,
        a.itemId.s,
        item.cid.s,
        item.folder.s,
        coalesce(am.language.s, c.language.s).s,
        a.name.s,
        am.content.s
      ),
      from(a)
        .innerJoin(am, am.id === a.id)
        .innerJoin(item, item.id === a.itemId)
        .innerJoin(c, c.id === item.cid)
    ).where(coll.map(cid => item.cid === cid))
      .build
      .query[ContentAndName]
      .streamWithChunkSize(chunkSize)

}
