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

final case class RNotificationChannelHttp(
    id: Ident,
    uid: Ident,
    url: LenientUri,
    created: Timestamp
) {
  def vary: RNotificationChannel =
    RNotificationChannel.Http(this)
}

object RNotificationChannelHttp {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_channel_http"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val url = Column[LenientUri]("url", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, uid, url, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def getById(id: Ident): ConnectionIO[Option[RNotificationChannelHttp]] =
    run(select(T.all), from(T), T.id === id).query[RNotificationChannelHttp].option

  def insert(r: RNotificationChannelHttp): ConnectionIO[Int] =
    DML.insert(T, T.all, sql"${r.id},${r.uid},${r.url},${r.created}")

  def update(r: RNotificationChannelHttp): ConnectionIO[Int] =
    DML.update(T, T.id === r.id && T.uid === r.uid, DML.set(T.url.setTo(r.url)))

  def getByAccount(account: AccountId): ConnectionIO[Vector[RNotificationChannelHttp]] = {
    val user = RUser.as("u")
    val http = as("c")
    Select(
      select(http.all),
      from(http).innerJoin(user, user.uid === http.uid),
      user.cid === account.collective && user.login === account.user
    ).build.query[RNotificationChannelHttp].to[Vector]
  }

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByAccount(id: Ident, account: AccountId): ConnectionIO[Int] = {
    val u = RUser.as("u")
    DML.delete(
      T,
      T.id === id && T.uid.in(Select(select(u.uid), from(u), u.isAccount(account)))
    )
  }
}
