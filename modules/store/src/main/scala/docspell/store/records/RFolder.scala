/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RFolder(
    id: Ident,
    name: String,
    collectiveId: CollectiveId,
    owner: Ident,
    created: Timestamp
)

object RFolder {

  def newFolder[F[_]: Sync](
      name: String,
      collective: CollectiveId,
      ownerUserId: Ident
  ): F[RFolder] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RFolder(nId, name, collective, ownerUserId, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "folder"

    val id = Column[Ident]("id", this)
    val name = Column[String]("name", this)
    val collective = Column[CollectiveId]("coll_id", this)
    val owner = Column[Ident]("owner", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, name, collective, owner, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(value: RFolder): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${value.id},${value.name},${value.collectiveId},${value.owner},${value.created}"
    )

  def update(v: RFolder): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === v.id && T.collective === v.collectiveId && T.owner === v.owner,
      DML.set(T.name.setTo(v.name))
    )

  def existsByName(coll: CollectiveId, folderName: String): ConnectionIO[Boolean] =
    run(select(count(T.id)), from(T), T.collective === coll && T.name === folderName)
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(folderId: Ident): ConnectionIO[Option[RFolder]] = {
    val sql = run(select(T.all), from(T), T.id === folderId)
    sql.query[RFolder].option
  }

  def requireIdByIdOrName(
      folderId: Ident,
      name: String,
      collective: CollectiveId
  ): ConnectionIO[Ident] = {
    val sql = run(
      select(T.id),
      from(T),
      T.id === folderId || (T.name === name && T.collective === collective)
    )
    sql.query[Ident].option.flatMap {
      case Some(id) => id.pure[ConnectionIO]
      case None =>
        Sync[ConnectionIO].raiseError(
          new Exception(s"No folder found for: id=${folderId.id} or name=$name")
        )
    }
  }

  def findAll(
      coll: CollectiveId,
      nameQ: Option[String],
      order: Table => Column[_]
  ): ConnectionIO[Vector[RFolder]] = {
    val nameFilter = nameQ.map(n => T.name.like(s"%${n.toLowerCase}%"))
    val sql = Select(select(T.all), from(T), T.collective === coll &&? nameFilter)
      .orderBy(order(T))
    sql.build.query[RFolder].to[Vector]
  }

  def delete(folderId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === folderId)
}
