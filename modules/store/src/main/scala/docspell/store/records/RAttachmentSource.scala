/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common.{FileKey, _}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

/** The origin file of an attachment. The `id` is shared with the attachment, to create a
  * 1-1 (or 0..1-1) relationship.
  */
case class RAttachmentSource(
    id: Ident, // same as RAttachment.id
    fileId: FileKey,
    name: Option[String],
    created: Timestamp
)

object RAttachmentSource {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_source"

    val id = Column[Ident]("id", this)
    val fileId = Column[FileKey]("file_id", this)
    val name = Column[String]("filename", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def of(ra: RAttachment): RAttachmentSource =
    RAttachmentSource(ra.id, ra.fileId, ra.name, ra.created)

  def insert(v: RAttachmentSource): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.id},${v.fileId},${v.name},${v.created}")

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentSource]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentSource].option

  def isSameFile(attachId: Ident, file: FileKey): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id === attachId && T.fileId === file).build
      .query[Int]
      .unique
      .map(_ > 0)

  def isConverted(attachId: Ident): ConnectionIO[Boolean] = {
    val s = RAttachmentSource.as("s")
    val a = RAttachment.as("a")
    Select(
      count(a.id).s,
      from(s).innerJoin(a, a.id === s.id),
      a.id === attachId && a.fileId <> s.fileId
    ).build.query[Int].unique.map(_ > 0)
  }

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentSource]] = {
    val b = RAttachment.as("b")
    val a = RAttachmentSource.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, a.id === b.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentSource].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RAttachmentSource]] = {
    val s = RAttachmentSource.as("s")
    val a = RAttachment.as("a")
    Select(select(s.all), from(s).innerJoin(a, a.id === s.id), a.itemId === itemId).build
      .query[RAttachmentSource]
      .to[Vector]
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentSource, RFileMeta)]] = {
    val a = RAttachmentSource.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")

    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, b.id === a.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentSource, RFileMeta)].to[Vector]
  }

}
