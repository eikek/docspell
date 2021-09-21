/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import scodec.bits.ByteVector

final case class RFileMeta(
    id: Ident,
    created: Timestamp,
    mimetype: MimeType,
    length: ByteSize,
    checksum: ByteVector
)

object RFileMeta {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "filemeta"

    val id        = Column[Ident]("file_id", this)
    val timestamp = Column[Timestamp]("created", this)
    val mimetype  = Column[MimeType]("mimetype", this)
    val length    = Column[ByteSize]("length", this)
    val checksum  = Column[ByteVector]("checksum", this)

    val all = NonEmptyList
      .of[Column[_]](id, timestamp, mimetype, length, checksum)

  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(r: RFileMeta): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${r.id},${r.created},${r.mimetype},${r.length},${r.checksum}")

  def findById(fid: Ident): ConnectionIO[Option[RFileMeta]] =
    run(select(T.all), from(T), T.id === fid).query[RFileMeta].option

  def findByIds(ids: List[Ident]): ConnectionIO[Vector[RFileMeta]] =
    NonEmptyList.fromList(ids) match {
      case Some(nel) =>
        run(select(T.all), from(T), T.id.in(nel)).query[RFileMeta].to[Vector]
      case None =>
        Vector.empty[RFileMeta].pure[ConnectionIO]
    }

  def findMime(fid: Ident): ConnectionIO[Option[MimeType]] =
    run(select(T.mimetype), from(T), T.id === fid)
      .query[MimeType]
      .option

  def delete(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)
}
