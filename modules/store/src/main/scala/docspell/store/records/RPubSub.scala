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
import docspell.store.qb.{Column, DML, TableDef}

import doobie._
import doobie.implicits._

/** A table for supporting naive pubsub across nodes. */
final case class RPubSub(
    id: Ident,
    nodeId: Ident,
    url: LenientUri,
    topic: String,
    counter: Int
)

object RPubSub {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName: String = "pubsub"

    val id = Column[Ident]("id", this)
    val nodeId = Column[Ident]("node_id", this)
    val url = Column[LenientUri]("url", this)
    val topic = Column[String]("topic", this)
    val counter = Column[Int]("counter", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, nodeId, url, topic, counter)
  }
  def as(alias: String): Table =
    Table(Some(alias))

  val T: Table = Table(None)

  def insert(r: RPubSub): ConnectionIO[Int] =
    DML.insert(T, T.all, sql"${r.id}, ${r.nodeId}, ${r.url}, ${r.topic}, ${r.counter}")

  /** Insert all topics with counter = 0 */
  def initTopics(
      nodeId: Ident,
      url: LenientUri,
      topics: NonEmptyList[String]
  ): ConnectionIO[Int] =
    DML.delete(T, T.nodeId === nodeId || T.url === url) *>
      topics.toList
        .traverse(t =>
          Ident
            .randomId[ConnectionIO]
            .flatMap(id => insert(RPubSub(id, nodeId, url, t, 0)))
        )
        .map(_.sum)

  def deleteTopics(nodeId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.nodeId === nodeId)

  def increment(url: LenientUri, topics: NonEmptyList[String]): ConnectionIO[Int] =
    DML.update(
      T,
      T.url === url && T.topic.in(topics),
      DML.set(
        T.counter.increment(1)
      )
    )

  def decrement(url: LenientUri, topics: NonEmptyList[String]): ConnectionIO[Int] =
    DML.update(
      T,
      T.url === url && T.topic.in(topics),
      DML.set(
        T.counter.decrement(1)
      )
    )

  def findSubs(topic: String, excludeNode: Ident): ConnectionIO[List[LenientUri]] =
    run(
      select(T.url),
      from(T),
      T.topic === topic && T.counter > 0 && T.nodeId <> excludeNode
    )
      .query[LenientUri]
      .to[List]
}
