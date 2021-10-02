/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList, OptionT}

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RShare(
    id: Ident,
    cid: Ident,
    name: Option[String],
    query: ItemQuery,
    enabled: Boolean,
    password: Option[Password],
    publishAt: Timestamp,
    publishUntil: Timestamp,
    views: Int,
    lastAccess: Option[Timestamp]
) {}

object RShare {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "item_share";

    val id = Column[Ident]("id", this)
    val cid = Column[Ident]("cid", this)
    val name = Column[String]("name", this)
    val query = Column[ItemQuery]("query", this)
    val enabled = Column[Boolean]("enabled", this)
    val password = Column[Password]("pass", this)
    val publishedAt = Column[Timestamp]("publish_at", this)
    val publishedUntil = Column[Timestamp]("publish_until", this)
    val views = Column[Int]("views", this)
    val lastAccess = Column[Timestamp]("last_access", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        cid,
        name,
        query,
        enabled,
        password,
        publishedAt,
        publishedUntil,
        views,
        lastAccess
      )
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RShare): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${r.id},${r.cid},${r.name},${r.query},${r.enabled},${r.password},${r.publishAt},${r.publishUntil},${r.views},${r.lastAccess}"
    )

  def incAccess(id: Ident): ConnectionIO[Int] =
    for {
      curTime <- Timestamp.current[ConnectionIO]
      n <- DML.update(
        T,
        T.id === id,
        DML.set(T.views.increment(1), T.lastAccess.setTo(curTime))
      )
    } yield n

  def updateData(r: RShare, removePassword: Boolean): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.cid === r.cid,
      DML.set(
        T.name.setTo(r.name),
        T.query.setTo(r.query),
        T.enabled.setTo(r.enabled),
        T.publishedUntil.setTo(r.publishUntil)
      ) ++ (if (r.password.isDefined || removePassword)
              List(T.password.setTo(r.password))
            else Nil)
    )

  def findOne(id: Ident, cid: Ident): OptionT[ConnectionIO, RShare] =
    OptionT(
      Select(select(T.all), from(T), T.id === id && T.cid === cid).build
        .query[RShare]
        .option
    )

  def findAllByCollective(cid: Ident): ConnectionIO[List[RShare]] =
    Select(select(T.all), from(T), T.cid === cid).build.query[RShare].to[List]

  def deleteByIdAndCid(id: Ident, cid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id && T.cid === cid)
}
