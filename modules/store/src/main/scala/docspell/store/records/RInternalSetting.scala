/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.implicits._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RInternalSetting(
    id: Ident,
    internalRouteKey: Ident
)

object RInternalSetting {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "internal_setting"

    val id = Column[Ident]("id", this)
    val internalRouteKey = Column[Ident]("internal_route_key", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, internalRouteKey)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val T = Table(None)

  private[this] val currentId = Ident.unsafe("4835448a-ff3a-4c2b-ad48-d06bf0d5720a")

  private def read: Query0[RInternalSetting] =
    Select(select(T.all), from(T), T.id === currentId).build
      .query[RInternalSetting]

  private def insert: ConnectionIO[Int] =
    for {
      rkey <- Ident.randomId[ConnectionIO]
      r = RInternalSetting(currentId, rkey)
      n <- DML.insert(T, T.all, sql"${r.id},${r.internalRouteKey}")
    } yield n

  def create: ConnectionIO[RInternalSetting] =
    for {
      s0 <- read.option
      s <- s0 match {
        case Some(a) => a.pure[ConnectionIO]
        case None =>
          insert.attemptSql *> withoutTransaction(read.unique)
      }
    } yield s

  // https://tpolecat.github.io/doobie/docs/18-FAQ.html#how-do-i-run-something-outside-of-a-transaction-
  /** Take a program `p` and return an equivalent one that first commits any ongoing
    * transaction, runs `p` without transaction handling, then starts a new transaction.
    */
  private def withoutTransaction[A](p: ConnectionIO[A]): ConnectionIO[A] =
    FC.setAutoCommit(true).bracket(_ => p)(_ => FC.setAutoCommit(false))
}
