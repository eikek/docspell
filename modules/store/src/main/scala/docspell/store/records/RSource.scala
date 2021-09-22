/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RSource(
    sid: Ident,
    cid: Ident,
    abbrev: String,
    description: Option[String],
    counter: Int,
    enabled: Boolean,
    priority: Priority,
    created: Timestamp,
    folderId: Option[Ident],
    fileFilter: Option[Glob],
    language: Option[Language],
    attachmentsOnly: Boolean
) {

  def fileFilterOrAll: Glob =
    fileFilter.getOrElse(Glob.all)
}

object RSource {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "source"

    val sid = Column[Ident]("sid", this)
    val cid = Column[Ident]("cid", this)
    val abbrev = Column[String]("abbrev", this)
    val description = Column[String]("description", this)
    val counter = Column[Int]("counter", this)
    val enabled = Column[Boolean]("enabled", this)
    val priority = Column[Priority]("priority", this)
    val created = Column[Timestamp]("created", this)
    val folder = Column[Ident]("folder_id", this)
    val fileFilter = Column[Glob]("file_filter", this)
    val language = Column[Language]("doc_lang", this)
    val attachOnly = Column[Boolean]("attachments_only", this)

    val all =
      NonEmptyList.of[Column[_]](
        sid,
        cid,
        abbrev,
        description,
        counter,
        enabled,
        priority,
        created,
        folder,
        fileFilter,
        language,
        attachOnly
      )
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val table = Table(None)

  def insert(v: RSource): ConnectionIO[Int] =
    DML.insert(
      table,
      table.all,
      fr"${v.sid},${v.cid},${v.abbrev},${v.description},${v.counter},${v.enabled},${v.priority},${v.created},${v.folderId},${v.fileFilter},${v.language},${v.attachmentsOnly}"
    )

  def updateNoCounter(v: RSource): ConnectionIO[Int] =
    DML.update(
      table,
      where(table.sid === v.sid, table.cid === v.cid),
      DML.set(
        table.cid.setTo(v.cid),
        table.abbrev.setTo(v.abbrev),
        table.description.setTo(v.description),
        table.enabled.setTo(v.enabled),
        table.priority.setTo(v.priority),
        table.folder.setTo(v.folderId),
        table.fileFilter.setTo(v.fileFilter),
        table.language.setTo(v.language),
        table.attachOnly.setTo(v.attachmentsOnly)
      )
    )

  def incrementCounter(source: String, coll: Ident): ConnectionIO[Int] =
    DML.update(
      table,
      where(table.abbrev === source, table.cid === coll),
      DML.set(table.counter.increment(1))
    )

  def existsById(id: Ident): ConnectionIO[Boolean] = {
    val sql = run(select(count(table.sid)), from(table), where(table.sid === id))
    sql.query[Int].unique.map(_ > 0)
  }

  def existsByAbbrev(coll: Ident, abb: String): ConnectionIO[Boolean] = {
    val sql = run(
      select(count(table.sid)),
      from(table),
      where(table.cid === coll, table.abbrev === abb)
    )
    sql.query[Int].unique.map(_ > 0)
  }

  def findEnabled(id: Ident): ConnectionIO[Option[RSource]] =
    findEnabledSql(id).query[RSource].option

  private[records] def findEnabledSql(id: Ident): Fragment =
    run(select(table.all), from(table), where(table.sid === id, table.enabled === true))

  def findCollective(sourceId: Ident): ConnectionIO[Option[Ident]] =
    run(select(table.cid), from(table), table.sid === sourceId).query[Ident].option

  def findAll(
      coll: Ident,
      order: Table => Column[_]
  ): ConnectionIO[Vector[RSource]] =
    findAllSql(coll, order).query[RSource].to[Vector]

  private[records] def findAllSql(
      coll: Ident,
      order: Table => Column[_]
  ): Fragment = {
    val t = RSource.as("s")
    Select(select(t.all), from(t), t.cid === coll).orderBy(order(t)).build
  }

  def delete(sourceId: Ident, coll: Ident): ConnectionIO[Int] =
    DML.delete(table, where(table.sid === sourceId, table.cid === coll))

  def removeFolder(folderId: Ident): ConnectionIO[Int] = {
    val empty: Option[Ident] = None
    DML.update(
      table,
      where(table.folder === folderId),
      DML.set(table.folder.setTo(empty))
    )
  }
}
