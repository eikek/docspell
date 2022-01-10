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
    userId: Ident,
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
    val userId = Column[Ident]("user_id", this)
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
        userId,
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
      fr"${r.id},${r.userId},${r.name},${r.query},${r.enabled},${r.password},${r.publishAt},${r.publishUntil},${r.views},${r.lastAccess}"
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
      T.id === r.id && T.userId === r.userId,
      DML.set(
        T.name.setTo(r.name),
        T.query.setTo(r.query),
        T.enabled.setTo(r.enabled),
        T.publishedUntil.setTo(r.publishUntil)
      ) ++ (if (r.password.isDefined || removePassword)
              List(T.password.setTo(r.password))
            else Nil)
    )

  def findOne(id: Ident, cid: Ident): OptionT[ConnectionIO, (RShare, RUser)] = {
    val s = RShare.as("s")
    val u = RUser.as("u")

    OptionT(
      Select(
        select(s.all, u.all),
        from(s).innerJoin(u, u.uid === s.userId),
        s.id === id && u.cid === cid
      ).build
        .query[(RShare, RUser)]
        .option
    )
  }

  private def activeCondition(t: Table, id: Ident, current: Timestamp): Condition =
    t.id === id && t.enabled === true && t.publishedUntil > current

  def findActive(
      id: Ident,
      current: Timestamp
  ): OptionT[ConnectionIO, (RShare, RUser)] = {
    val s = RShare.as("s")
    val u = RUser.as("u")

    OptionT(
      Select(
        select(s.all, u.all),
        from(s).innerJoin(u, s.userId === u.uid),
        activeCondition(s, id, current)
      ).build.query[(RShare, RUser)].option
    )
  }

  def findCurrentActive(id: Ident): OptionT[ConnectionIO, (RShare, RUser)] =
    OptionT.liftF(Timestamp.current[ConnectionIO]).flatMap(now => findActive(id, now))

  def findActivePassword(id: Ident): OptionT[ConnectionIO, Option[Password]] =
    OptionT(Timestamp.current[ConnectionIO].flatMap { now =>
      Select(select(T.password), from(T), activeCondition(T, id, now)).build
        .query[Option[Password]]
        .option
    })

  def findOneByCollective(
      cid: Ident,
      enabled: Option[Boolean],
      nameOrId: String
  ): ConnectionIO[Option[RShare]] = {
    val s = RShare.as("s")
    val u = RUser.as("u")

    Select(
      select(s.all),
      from(s).innerJoin(u, u.uid === s.userId),
      u.cid === cid &&
        (s.name === nameOrId || s.id ==== nameOrId) &&?
        enabled.map(e => s.enabled === e)
    ).build.query[RShare].option
  }

  def findAllByCollective(
      cid: Ident,
      ownerLogin: Option[Ident],
      q: Option[String]
  ): ConnectionIO[List[(RShare, RUser)]] = {
    val s = RShare.as("s")
    val u = RUser.as("u")

    val ownerQ = ownerLogin.map(name => u.login === name)
    val nameQ = q.map(n => s.name.like(s"%$n%"))

    Select(
      select(s.all, u.all),
      from(s).innerJoin(u, u.uid === s.userId),
      u.cid === cid &&? ownerQ &&? nameQ
    )
      .orderBy(s.publishedAt.desc)
      .build
      .query[(RShare, RUser)]
      .to[List]
  }

  def deleteByIdAndCid(id: Ident, cid: Ident): ConnectionIO[Int] = {
    val u = RUser.T
    DML.delete(T, T.id === id && T.userId.in(Select(u.uid.s, from(u), u.cid === cid)))
  }
}
