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

final case class RNotificationChannelGotify(
    id: Ident,
    uid: Ident,
    url: LenientUri,
    appKey: Password,
    created: Timestamp
) {
  def vary: RNotificationChannel =
    RNotificationChannel.Gotify(this)
}

object RNotificationChannelGotify {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_channel_gotify"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val url = Column[LenientUri]("url", this)
    val appKey = Column[Password]("app_key", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, uid, url, appKey, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def getById(id: Ident): ConnectionIO[Option[RNotificationChannelGotify]] =
    run(select(T.all), from(T), T.id === id).query[RNotificationChannelGotify].option

  def insert(r: RNotificationChannelGotify): ConnectionIO[Int] =
    DML.insert(T, T.all, sql"${r.id},${r.uid},${r.url},${r.appKey},${r.created}")

  def update(r: RNotificationChannelGotify): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.url.setTo(r.url),
        T.appKey.setTo(r.appKey)
      )
    )

  def getByAccount(
      account: AccountId
  ): ConnectionIO[Vector[RNotificationChannelGotify]] = {
    val user = RUser.as("u")
    val gotify = as("c")
    Select(
      select(gotify.all),
      from(gotify).innerJoin(user, user.uid === gotify.uid),
      user.cid === account.collective && user.login === account.user
    ).build.query[RNotificationChannelGotify].to[Vector]
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
