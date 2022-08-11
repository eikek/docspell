/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.notification.api.ChannelType
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RNotificationChannelGotify(
    id: Ident,
    uid: Ident,
    name: Option[String],
    url: LenientUri,
    appKey: Password,
    priority: Option[Int],
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
    val name = Column[String]("name", this)
    val url = Column[LenientUri]("url", this)
    val appKey = Column[Password]("app_key", this)
    val priority = Column[Int]("priority", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, uid, name, url, appKey, priority, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def getById(
      userId: Ident
  )(id: Ident): ConnectionIO[Option[RNotificationChannelGotify]] =
    run(select(T.all), from(T), T.id === id && T.uid === userId)
      .query[RNotificationChannelGotify]
      .option

  def insert(r: RNotificationChannelGotify): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.uid},${r.name},${r.url},${r.appKey},${r.priority},${r.created}"
    )

  def update(r: RNotificationChannelGotify): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.url.setTo(r.url),
        T.appKey.setTo(r.appKey),
        T.priority.setTo(r.priority),
        T.name.setTo(r.name)
      )
    )

  def getByAccount(
      userId: Ident
  ): ConnectionIO[Vector[RNotificationChannelGotify]] = {
    val gotify = as("c")
    Select(
      select(gotify.all),
      from(gotify),
      gotify.uid === userId
    ).build.query[RNotificationChannelGotify].to[Vector]
  }

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByAccount(id: Ident, userId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id && T.uid === userId)

  def findRefs(ids: NonEmptyList[Ident]): Select =
    Select(
      select(T.id.s, const(ChannelType.Gotify.name), T.name.s),
      from(T),
      T.id.in(ids)
    )
}
