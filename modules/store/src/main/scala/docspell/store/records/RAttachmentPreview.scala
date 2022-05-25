/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList, OptionT}
import cats.syntax.all._

import docspell.common.{FileKey, _}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

/** A preview image of an attachment. The `id` is shared with the attachment, to create a
  * 1-1 (or 0..1-1) relationship.
  */
case class RAttachmentPreview(
    id: Ident, // same as RAttachment.id
    fileId: FileKey,
    name: Option[String],
    created: Timestamp
)

object RAttachmentPreview {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_preview"

    val id = Column[Ident]("id", this)
    val fileId = Column[FileKey]("file_id", this)
    val name = Column[String]("filename", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RAttachmentPreview): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.id},${v.fileId},${v.name},${v.created}")

  def update(r: RAttachmentPreview): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id,
      DML.set(
        T.fileId.setTo(r.fileId),
        T.name.setTo(r.name)
      )
    )

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentPreview]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentPreview].option

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def upsert(r: RAttachmentPreview): ConnectionIO[Option[FileKey]] =
    OptionT(findById(r.id))
      .semiflatMap(existing =>
        update(existing.copy(fileId = r.fileId, name = r.name)).as(Some(existing.fileId))
      )
      .getOrElseF(insert(r).as(None))

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentPreview]] = {
    val b = RAttachment.as("b")
    val a = RAttachmentPreview.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, a.id === b.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentPreview].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RAttachmentPreview]] = {
    val s = RAttachmentPreview.as("s")
    val a = RAttachment.as("a")
    Select(
      select(s.all),
      from(s)
        .innerJoin(a, s.id === a.id),
      a.itemId === itemId
    ).build.query[RAttachmentPreview].to[Vector]
  }

  def findByItemAndCollective(
      itemId: Ident,
      coll: Ident
  ): ConnectionIO[Option[RAttachmentPreview]] = {
    val s = RAttachmentPreview.as("s")
    val a = RAttachment.as("a")
    val i = RItem.as("i")

    Select(
      select(s.all).append(a.position.s),
      from(s)
        .innerJoin(a, s.id === a.id)
        .innerJoin(i, i.id === a.itemId),
      a.itemId === itemId && i.cid === coll
    ).build
      .query[(RAttachmentPreview, Int)]
      .to[Vector]
      .map(_.sortBy(_._2).headOption.map(_._1))
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentPreview, RFileMeta)]] = {
    val a = RAttachmentPreview.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")

    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, b.id === a.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentPreview, RFileMeta)].to[Vector]
  }
}
