/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import java.time.Instant

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.syntax.MimeTypes._

import bitpeace.FileMeta
import bitpeace.Mimetype
import doobie._
import doobie.implicits._

object RFileMeta {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "filemeta"

    val id        = Column[Ident]("id", this)
    val timestamp = Column[Instant]("timestamp", this)
    val mimetype  = Column[Mimetype]("mimetype", this)
    val length    = Column[Long]("length", this)
    val checksum  = Column[String]("checksum", this)
    val chunks    = Column[Int]("chunks", this)
    val chunksize = Column[Int]("chunksize", this)

    val all = NonEmptyList
      .of[Column[_]](id, timestamp, mimetype, length, checksum, chunks, chunksize)

  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def findById(fid: Ident): ConnectionIO[Option[FileMeta]] = {
    import bitpeace.sql._

    run(select(T.all), from(T), T.id === fid).query[FileMeta].option
  }

  def findByIds(ids: List[Ident]): ConnectionIO[Vector[FileMeta]] = {
    import bitpeace.sql._

    NonEmptyList.fromList(ids) match {
      case Some(nel) =>
        run(select(T.all), from(T), T.id.in(nel)).query[FileMeta].to[Vector]
      case None =>
        Vector.empty[FileMeta].pure[ConnectionIO]
    }
  }

  def findMime(fid: Ident): ConnectionIO[Option[MimeType]] = {
    import bitpeace.sql._

    run(select(T.mimetype), from(T), T.id === fid)
      .query[Mimetype]
      .option
      .map(_.map(_.toLocal))
  }
}
