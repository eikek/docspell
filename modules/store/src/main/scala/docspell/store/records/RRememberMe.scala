/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RRememberMe(id: Ident, accountId: AccountId, created: Timestamp, uses: Int) {}

object RRememberMe {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "rememberme"

    val id       = Column[Ident]("id", this)
    val cid      = Column[Ident]("cid", this)
    val username = Column[Ident]("login", this)
    val created  = Column[Timestamp]("created", this)
    val uses     = Column[Int]("uses", this)
    val all      = NonEmptyList.of[Column[_]](id, cid, username, created, uses)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def generate[F[_]: Sync](account: AccountId): F[RRememberMe] =
    for {
      c <- Timestamp.current[F]
      i <- Ident.randomId[F]
    } yield RRememberMe(i, account, c, 0)

  def insert(v: RRememberMe): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.accountId.collective},${v.accountId.user},${v.created},${v.uses}"
    )

  def insertNew(acc: AccountId): ConnectionIO[RRememberMe] =
    generate[ConnectionIO](acc).flatMap(v => insert(v).map(_ => v))

  def findById(rid: Ident): ConnectionIO[Option[RRememberMe]] =
    run(select(T.all), from(T), T.id === rid).query[RRememberMe].option

  def delete(rid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === rid)

  def incrementUse(rid: Ident): ConnectionIO[Int] =
    DML.update(T, T.id === rid, DML.set(T.uses.increment(1)))

  def useRememberMe(
      rid: Ident,
      minCreated: Timestamp
  ): ConnectionIO[Option[RRememberMe]] = {
    val get = run(select(T.all), from(T), T.id === rid && T.created > minCreated)
      .query[RRememberMe]
      .option
    for {
      inv <- get
      _   <- incrementUse(rid)
    } yield inv
  }

  def deleteOlderThan(ts: Timestamp): ConnectionIO[Int] =
    DML.delete(T, T.created < ts)
}
