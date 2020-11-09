package docspell.store.queries

import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QAttachment {
  private[this] val logger = org.log4s.getLogger

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
    val AC = RAttachment.Columns
    val MC = RAttachmentMeta.Columns
    val IC = RItem.Columns

    val q = fr"SELECT" ++ MC.proposals
      .prefix("m")
      .f ++ fr"FROM" ++ RAttachmentMeta.table ++ fr"m" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ AC.id
        .prefix("a")
        .is(MC.id.prefix("m")) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ AC.itemId
        .prefix("a")
        .is(IC.id.prefix("i")) ++
      fr"WHERE" ++ and(AC.itemId.prefix("a").is(itemId), IC.cid.prefix("i").is(coll))

    for {
      ml <- q.query[MetaProposalList].to[Vector]
    } yield MetaProposalList.flatten(ml)
  }

  def getAttachmentMeta(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentMeta]] = {
    val AC = RAttachment.Columns
    val MC = RAttachmentMeta.Columns
    val IC = RItem.Columns

    val q =
      fr"SELECT" ++ commas(
        MC.all.map(_.prefix("m").f)
      ) ++ fr"FROM" ++ RItem.table ++ fr"i" ++
        fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ IC.id
          .prefix("i")
          .is(AC.itemId.prefix("a")) ++
        fr"INNER JOIN" ++ RAttachmentMeta.table ++ fr"m ON" ++ AC.id
          .prefix("a")
          .is(MC.id.prefix("m")) ++
        fr"WHERE" ++ and(
          AC.id.prefix("a").is(attachId),
          IC.cid.prefix("i").is(collective)
        )

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
  ): Stream[ConnectionIO, ContentAndName] = {
    val aId      = RAttachment.Columns.id.prefix("a")
    val aItem    = RAttachment.Columns.itemId.prefix("a")
    val aName    = RAttachment.Columns.name.prefix("a")
    val mId      = RAttachmentMeta.Columns.id.prefix("m")
    val mContent = RAttachmentMeta.Columns.content.prefix("m")
    val iId      = RItem.Columns.id.prefix("i")
    val iColl    = RItem.Columns.cid.prefix("i")
    val iFolder  = RItem.Columns.folder.prefix("i")
    val cId      = RCollective.Columns.id.prefix("c")
    val cLang    = RCollective.Columns.language.prefix("c")

    val cols = Seq(aId, aItem, iColl, iFolder, cLang, aName, mContent)
    val from = RAttachment.table ++ fr"a INNER JOIN" ++
      RAttachmentMeta.table ++ fr"m ON" ++ aId.is(mId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ iId.is(aItem) ++
      fr"INNER JOIN" ++ RCollective.table ++ fr"c ON" ++ cId.is(iColl)

    val where = coll.map(cid => iColl.is(cid)).getOrElse(Fragment.empty)

    selectSimple(cols, from, where)
      .query[ContentAndName]
      .streamWithChunkSize(chunkSize)
  }
}
