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

final case class RDownloadQuery(
    id: Ident,
    cid: Ident,
    fileId: FileKey,
    fileCount: Int,
    created: Timestamp,
    lastAccess: Option[Timestamp],
    accessCount: Int
) {}

object RDownloadQuery {

  case class Table(alias: Option[String]) extends TableDef {
    val tableName = "download_query"

    val id: Column[Ident] = Column("id", this)
    val cid: Column[Ident] = Column("cid", this)
    val fileId: Column[FileKey] = Column("file_id", this)
    val fileCount: Column[Int] = Column("file_count", this)
    val created: Column[Timestamp] = Column("created", this)
    val lastAccess: Column[Timestamp] = Column("last_access", this)
    val accessCount: Column[Int] = Column("access_count", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, cid, fileId, fileCount, created, lastAccess, accessCount)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val T = Table(None)

  def insert(r: RDownloadQuery): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.cid},${r.fileId},${r.fileCount},${r.created},${r.lastAccess},${r.accessCount}"
    )

  def existsById(id: Ident): ConnectionIO[Boolean] =
    Select(select(count(T.id)), from(T), T.id === id).build.query[Int].unique.map(_ > 0)

  def findById(id: Ident): ConnectionIO[Option[(RDownloadQuery, RFileMeta)]] = {
    val dq = RDownloadQuery.as("dq")
    val fm = RFileMeta.as("fm")
    Select(
      select(dq.all, fm.all),
      from(dq).innerJoin(fm, fm.id === dq.fileId),
      dq.id === id
    ).build
      .query[(RDownloadQuery, RFileMeta)]
      .option
  }

  def updateAccess(id: Ident, ts: Timestamp): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === id,
      DML.set(
        T.lastAccess.setTo(ts),
        T.accessCount.increment(1)
      )
    )

  def updateAccessNow(id: Ident): ConnectionIO[Int] =
    Timestamp
      .current[ConnectionIO]
      .flatMap(updateAccess(id, _))

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByFileKey(fkey: FileKey): ConnectionIO[Int] =
    DML.delete(T, T.fileId === fkey)

  def findOlderThan(ts: Timestamp, batch: Int): ConnectionIO[List[FileKey]] =
    Select(
      select(T.fileId),
      from(T),
      T.lastAccess.isNull || T.lastAccess < ts
    ).limit(batch)
      .build
      .query[FileKey]
      .to[List]
}
