/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList => Nel}
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.totp.{Key, Mac}

import doobie._
import doobie.implicits._

final case class RTotp(
    userId: Ident,
    enabled: Boolean,
    secret: Key,
    created: Timestamp
) {}

object RTotp {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "totp"

    val userId = Column[Ident]("user_id", this)
    val enabled = Column[Boolean]("enabled", this)
    val secret = Column[Key]("secret", this)
    val created = Column[Timestamp]("created", this)

    val all = Nel.of(userId, enabled, secret, created)
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def generate[F[_]: Sync](userId: Ident, mac: Mac): F[RTotp] =
    for {
      now <- Timestamp.current[F]
      key <- Key.generate[F](mac)
    } yield RTotp(userId, enabled = false, key, now)

  def insert(r: RTotp): ConnectionIO[Int] =
    DML.insert(T, T.all, sql"${r.userId},${r.enabled},${r.secret},${r.created}")

  def updateDisabled(r: RTotp): ConnectionIO[Int] =
    DML.update(
      T,
      T.enabled === false && T.userId === r.userId,
      DML.set(
        T.secret.setTo(r.secret),
        T.created.setTo(r.created)
      )
    )

  def setEnabled(userId: Ident, enabled: Boolean): ConnectionIO[Int] =
    DML.update(T, T.userId === userId, DML.set(T.enabled.setTo(enabled)))

  def isEnabled(userId: Ident): ConnectionIO[Boolean] = {
    val t = RTotp.as("t")
    Select(
      select(count(t.userId)),
      from(t),
      t.userId === userId && t.enabled === true
    ).build.query[Int].unique.map(_ > 0)
  }

  def findEnabledByLogin(
      accountId: AccountId,
      enabled: Boolean
  ): ConnectionIO[Option[RTotp]] = {
    val t = RTotp.as("t")
    val u = RUser.as("u")
    val c = RCollective.as("c")
    Select(
      select(t.all),
      from(t).innerJoin(u, t.userId === u.uid).innerJoin(c, c.id === u.cid),
      u.login === accountId.user && c.name === accountId.collective && t.enabled === enabled
    ).build.query[RTotp].option
  }

  def findEnabledByUserId(
      userId: Ident,
      enabled: Boolean
  ): ConnectionIO[Option[RTotp]] = {
    val t = RTotp.as("t")
    Select(
      select(t.all),
      from(t),
      t.userId === userId && t.enabled === enabled
    ).build.query[RTotp].option
  }

  def existsByLogin(accountId: AccountId): ConnectionIO[Boolean] = {
    val t = RTotp.as("t")
    val u = RUser.as("u")
    val c = RCollective.as("c")
    Select(
      select(count(t.userId)),
      from(t).innerJoin(u, t.userId === u.uid).innerJoin(c, c.id === u.cid),
      u.login === accountId.user && c.name === accountId.collective
    ).build
      .query[Int]
      .unique
      .map(_ > 0)
  }

  def existsByUserId(userId: Ident): ConnectionIO[Boolean] = {
    val t = RTotp.as("t")
    Select(select(count(t.userId)), from(t), t.userId === userId).build
      .query[Int]
      .unique
      .map(_ > 0)
  }
}
