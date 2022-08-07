/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.OptionT
import cats.data.{NonEmptyList => Nel}
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.Store
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._

object QAttachment {
  private val a = RAttachment.as("a")
  private val as = RAttachmentSource.as("ats")
  private val item = RItem.as("i")
  private val am = RAttachmentMeta.as("am")
  private val c = RCollective.as("c")
  private val im = RItemProposal.as("im")
  private val fm = RFileMeta.as("fm")

  def attachmentSourceFile(itemId: Ident): ConnectionIO[List[AttachedFile]] =
    Select(
      combineNel(
        select(as.id, as.name, a.position, am.language),
        select(fm.mimetype, fm.length, fm.checksum)
      ),
      from(a)
        .innerJoin(as, a.id === as.id)
        .innerJoin(fm, fm.id === as.fileId)
        .leftJoin(am, am.id === a.id),
      a.itemId === itemId
    ).orderBy(a.position).build.query[AttachedFile].to[List]

  def attachmentFile(itemId: Ident): ConnectionIO[List[AttachedFile]] =
    Select(
      combineNel(
        select(a.id, a.name, a.position, am.language),
        select(fm.mimetype, fm.length, fm.checksum)
      ),
      from(a)
        .innerJoin(fm, fm.id === a.fileId)
        .leftJoin(am, am.id === a.id),
      a.itemId === itemId
    ).orderBy(a.position).build.query[AttachedFile].to[List]

  def deletePreview[F[_]: Sync](store: Store[F])(attachId: Ident): F[Int] = {
    val findPreview =
      for {
        rp <- RAttachmentPreview.findById(attachId)
      } yield rp.toSeq

    Stream
      .evalSeq(store.transact(findPreview))
      .map(_.fileId)
      .evalTap(_ => store.transact(RAttachmentPreview.delete(attachId)))
      .evalMap(store.fileRepo.delete)
      .map(_ => 1)
      .compile
      .foldMonoid
  }

  /** Deletes an attachment, its related source and meta data records. It will only delete
    * an related archive file, if this is the last attachment in that archive.
    */
  def deleteSingleAttachment[F[_]: Sync](
      store: Store[F]
  )(attachId: Ident, coll: CollectiveId): F[Int] = {
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
          .evalMap(store.fileRepo.delete)
          .map(_ => 1)
          .compile
          .foldMonoid
    } yield n + k + f
  }

  /** This deletes the attachment and *all* its related files. This used when deleting an
    * item and should not be used to delete a *single* attachment where the item should
    * stay.
    */
  private def deleteAttachment[F[_]: Sync](store: Store[F])(ra: RAttachment): F[Int] = {
    val logger = docspell.logging.getLogger[F]
    for {
      _ <- logger.debug(s"Deleting attachment: ${ra.id.id}")
      s <- store.transact(RAttachmentSource.findById(ra.id))
      p <- store.transact(RAttachmentPreview.findById(ra.id))
      n <- store.transact(RAttachment.delete(ra.id))
      _ <- logger.debug(
        s"Deleted $n meta records (source, meta, preview, archive). Deleting binaries now."
      )
      f <-
        Stream
          .emits(ra.fileId +: (s.map(_.fileId).toSeq ++ p.map(_.fileId).toSeq))
          .evalMap(store.fileRepo.delete)
          .map(_ => 1)
          .compile
          .foldMonoid
    } yield n + f
  }

  def deleteArchive[F[_]: Sync](store: Store[F])(attachId: Ident): F[Int] =
    (for {
      aa <- OptionT(store.transact(RAttachmentArchive.findById(attachId)))
      n <- OptionT.liftF(store.transact(RAttachmentArchive.deleteAll(aa.fileId)))
      _ <- OptionT.liftF(
        Stream
          .emit(aa.fileId)
          .evalMap(store.fileRepo.delete)
          .compile
          .drain
      )
    } yield n).getOrElse(0)

  def deleteItemAttachments[F[_]: Sync](
      store: Store[F]
  )(itemId: Ident, coll: CollectiveId): F[Int] = {
    val logger = docspell.logging.getLogger[F]
    for {
      ras <- store.transact(RAttachment.findByItemAndCollective(itemId, coll))
      _ <- logger.info(
        s"Have ${ras.size} attachments to delete. Must first delete archive entries"
      )
      a <- ras.traverse(a => deleteArchive(store)(a.id))
      _ <- logger.debug(s"Deleted ${a.sum} archive entries")
      ns <- ras.traverse(deleteAttachment[F](store))
    } yield ns.sum
  }

  def getMetaProposals(
      itemId: Ident,
      coll: CollectiveId
  ): ConnectionIO[MetaProposalList] = {
    val qa = Select(
      select(am.proposals),
      from(am)
        .innerJoin(a, a.id === am.id)
        .innerJoin(item, a.itemId === item.id),
      a.itemId === itemId && item.cid === coll
    ).build

    val qi = Select(
      select(im.classifyProposals),
      from(im)
        .innerJoin(item, item.id === im.itemId),
      item.cid === coll && im.itemId === itemId
    ).build

    for {
      mla <- qa.query[MetaProposalList].to[Vector]
      mli <- qi.query[MetaProposalList].to[Vector]
    } yield MetaProposalList
      .flatten(mla)
      .insertSecond(MetaProposalList.flatten(mli))
  }

  def getAttachmentMeta(
      attachId: Ident,
      collective: CollectiveId
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

  def getAttachmentMetaOfItem(itemId: Ident): ConnectionIO[Vector[RAttachmentMeta]] =
    Select(
      select(am.all),
      from(am)
        .innerJoin(a, a.id === am.id),
      a.itemId === itemId
    ).orderBy(a.position.asc)
      .build
      .query[RAttachmentMeta]
      .to[Vector]

  case class ContentAndName(
      id: Ident,
      item: Ident,
      collective: CollectiveId,
      folder: Option[Ident],
      lang: Language,
      name: Option[String],
      content: Option[String]
  )
  def allAttachmentMetaAndName(
      coll: Option[CollectiveId],
      itemIds: Option[Nel[Ident]],
      itemStates: Nel[ItemState],
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
    ).where(
      item.state.in(itemStates) &&?
        itemIds.map(ids => item.id.in(ids)) &&?
        coll.map(cid => item.cid === cid)
    ).build
      .query[ContentAndName]
      .streamWithChunkSize(chunkSize)
}
