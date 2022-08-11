/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common.{FileKey, _}
import docspell.store.qb.DSL._
import docspell.store.qb.TableDef
import docspell.store.qb._

import doobie._
import doobie.implicits._

/** The archive file of some attachment. The `id` is shared with the attachment, to create
  * a 0..1-1 relationship.
  */
case class RAttachmentArchive(
    id: Ident, // same as RAttachment.id
    fileId: FileKey,
    name: Option[String],
    messageId: Option[String],
    created: Timestamp
)

object RAttachmentArchive {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_archive"

    val id = Column[Ident]("id", this)
    val fileId = Column[FileKey]("file_id", this)
    val name = Column[String]("filename", this)
    val messageId = Column[String]("message_id", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, messageId, created)
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def of(ra: RAttachment, mId: Option[String]): RAttachmentArchive =
    RAttachmentArchive(ra.id, ra.fileId, ra.name, mId, ra.created)

  def insert(v: RAttachmentArchive): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.fileId},${v.name},${v.messageId},${v.created}"
    )

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentArchive]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentArchive].option

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def deleteAll(fId: FileKey): ConnectionIO[Int] =
    DML.delete(T, T.fileId === fId)

  def findByIdAndCollective(
      attachId: Ident,
      collective: CollectiveId
  ): ConnectionIO[Option[RAttachmentArchive]] = {
    val b = RAttachment.as("b")
    val a = RAttachmentArchive.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, b.id === a.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentArchive].option
  }

  def findByMessageIdAndCollective(
      messageIds: NonEmptyList[String],
      collective: CollectiveId
  ): ConnectionIO[Vector[RAttachmentArchive]] = {
    val b = RAttachment.as("b")
    val a = RAttachmentArchive.as("a")
    val i = RItem.as("i")
    Select(
      select(a.all),
      from(a)
        .innerJoin(b, b.id === a.id)
        .innerJoin(i, i.id === b.itemId),
      a.messageId.in(messageIds) && i.cid === collective
    ).build.query[RAttachmentArchive].to[Vector]
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentArchive, RFileMeta)]] = {
    val a = RAttachmentArchive.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")
    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, a.id === b.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentArchive, RFileMeta)].to[Vector]
  }

  /** If the given attachment id has an associated archive, this returns the number of all
    * associated attachments. Returns 0 if there is no archive for the given attachment.
    */
  def countEntries(attachId: Ident): ConnectionIO[Int] =
    Select(
      count(T.id).s,
      from(T),
      T.fileId.in(Select(T.fileId.s, from(T), T.id === attachId))
    ).build.query[Int].unique

}
