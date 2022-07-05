/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.Order
import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RItemLink(
    id: Ident,
    cid: CollectiveId,
    item1: Ident,
    item2: Ident,
    created: Timestamp
)

object RItemLink {
  def create[F[_]: Sync](cid: CollectiveId, item1: Ident, item2: Ident): F[RItemLink] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RItemLink(id, cid, item1, item2, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "item_link"

    val id: Column[Ident] = Column("id", this)
    val cid: Column[CollectiveId] = Column("coll_id", this)
    val item1: Column[Ident] = Column("item1", this)
    val item2: Column[Ident] = Column("item2", this)
    val created: Column[Timestamp] = Column("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, cid, item1, item2, created)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val T: Table = Table(None)

  private def orderIds(item1: Ident, item2: Ident): (Ident, Ident) = {
    val i1 = Order[Ident].min(item1, item2)
    val i2 = Order[Ident].max(item1, item2)
    (i1, i2)
  }

  def insert(r: RItemLink): ConnectionIO[Int] = {
    val (i1, i2) = orderIds(r.item1, r.item2)
    DML.insertSilent(T, T.all, sql"${r.id},${r.cid},$i1,$i2,${r.created}")
  }

  def insertNew(cid: CollectiveId, item1: Ident, item2: Ident): ConnectionIO[Int] =
    create[ConnectionIO](cid, item1, item2).flatMap(insert)

  def update(r: RItemLink): ConnectionIO[Int] = {
    val (i1, i2) = orderIds(r.item1, r.item2)
    DML.update(
      T,
      T.id === r.id && T.cid === r.cid,
      DML.set(
        T.item1.setTo(i1),
        T.item2.setTo(i2)
      )
    )
  }

  def exists(cid: CollectiveId, item1: Ident, item2: Ident): ConnectionIO[Boolean] = {
    val (i1, i2) = orderIds(item1, item2)
    Select(
      select(count(T.id)),
      from(T),
      T.cid === cid && T.item1 === i1 && T.item2 === i2
    ).build.query[Int].unique.map(_ > 0)
  }

  def findLinked(cid: CollectiveId, item: Ident): ConnectionIO[Vector[Ident]] =
    union(
      Select(
        select(T.item1),
        from(T),
        T.cid === cid && T.item2 === item
      ),
      Select(
        select(T.item2),
        from(T),
        T.cid === cid && T.item1 === item
      )
    ).build.query[Ident].to[Vector]

  def deleteAll(
      cid: CollectiveId,
      item: Ident,
      related: NonEmptyList[Ident]
  ): ConnectionIO[Int] =
    DML.delete(
      T,
      T.cid === cid && (
        (T.item1 === item && T.item2.in(related)) ||
          (T.item2 === item && T.item1.in(related))
      )
    )

  def delete(cid: CollectiveId, item1: Ident, item2: Ident): ConnectionIO[Int] = {
    val (i1, i2) = orderIds(item1, item2)
    DML.delete(T, T.cid === cid && T.item1 === i1 && T.item2 === i2)
  }
}
