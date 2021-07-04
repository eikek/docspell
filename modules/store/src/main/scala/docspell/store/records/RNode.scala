/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records
import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RNode(
    id: Ident,
    nodeType: NodeType,
    url: LenientUri,
    updated: Timestamp,
    created: Timestamp,
    notFound: Int
) {}

object RNode {

  def apply[F[_]: Sync](id: Ident, nodeType: NodeType, uri: LenientUri): F[RNode] =
    Timestamp.current[F].map(now => RNode(id, nodeType, uri, now, now, 0))

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "node"

    val id       = Column[Ident]("id", this)
    val nodeType = Column[NodeType]("type", this)
    val url      = Column[LenientUri]("url", this)
    val updated  = Column[Timestamp]("updated", this)
    val created  = Column[Timestamp]("created", this)
    val notFound = Column[Int]("not_found", this)
    val all      = NonEmptyList.of[Column[_]](id, nodeType, url, updated, created, notFound)
  }

  def as(alias: String): Table =
    Table(Some(alias))
  val T = Table(None)

  def insert(v: RNode): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      fr"${v.id},${v.nodeType},${v.url},${v.updated},${v.created},${v.notFound}"
    )
  }

  def update(v: RNode): ConnectionIO[Int] = {
    val t = Table(None)
    DML
      .update(
        t,
        t.id === v.id,
        DML.set(
          t.nodeType.setTo(v.nodeType),
          t.url.setTo(v.url),
          t.updated.setTo(v.updated)
        )
      )
  }

  def incrementNotFound(nid: Ident): ConnectionIO[Int] =
    Timestamp
      .current[ConnectionIO]
      .flatMap(now =>
        DML
          .update(T, T.id === nid, DML.set(T.notFound.increment(1), T.updated.setTo(now)))
      )

  def resetNotFound(id: Ident): ConnectionIO[Int] =
    Timestamp
      .current[ConnectionIO]
      .flatMap(now =>
        DML
          .update(T, T.id === id, DML.set(T.notFound.setTo(0), T.updated.setTo(now)))
      )

  def set(v: RNode): ConnectionIO[Int] =
    for {
      n <- update(v)
      k <- if (n == 0) insert(v) else 0.pure[ConnectionIO]
    } yield n + k

  def delete(appId: Ident): ConnectionIO[Int] = {
    val t = Table(None)
    DML.delete(t, t.id === appId)
  }

  def findAll(nt: NodeType): ConnectionIO[Vector[RNode]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.nodeType === nt).query[RNode].to[Vector]
  }

  def findById(nodeId: Ident): ConnectionIO[Option[RNode]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.id === nodeId).query[RNode].option
  }

  def streamAll: Stream[ConnectionIO, RNode] =
    run(select(T.all), from(T)).query[RNode].streamWithChunkSize(50)

  def deleteNotFound(min: Int): ConnectionIO[Int] =
    DML.delete(T, T.notFound >= min)
}
