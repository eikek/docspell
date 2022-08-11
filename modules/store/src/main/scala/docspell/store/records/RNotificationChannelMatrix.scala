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

final case class RNotificationChannelMatrix(
    id: Ident,
    uid: Ident,
    name: Option[String],
    homeServer: LenientUri,
    roomId: String,
    accessToken: Password,
    messageType: String,
    created: Timestamp
) {
  def vary: RNotificationChannel =
    RNotificationChannel.Matrix(this)
}

object RNotificationChannelMatrix {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_channel_matrix"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val name = Column[String]("name", this)
    val homeServer = Column[LenientUri]("home_server", this)
    val roomId = Column[String]("room_id", this)
    val accessToken = Column[Password]("access_token", this)
    val messageType = Column[String]("message_type", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        uid,
        name,
        homeServer,
        roomId,
        accessToken,
        messageType,
        created
      )
  }
  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RNotificationChannelMatrix): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.uid},${r.name},${r.homeServer},${r.roomId},${r.accessToken},${r.messageType},${r.created}"
    )

  def update(r: RNotificationChannelMatrix): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.homeServer.setTo(r.homeServer),
        T.roomId.setTo(r.roomId),
        T.accessToken.setTo(r.accessToken),
        T.messageType.setTo(r.messageType),
        T.name.setTo(r.name)
      )
    )

  def getById(userId: Ident)(
      id: Ident
  ): ConnectionIO[Option[RNotificationChannelMatrix]] =
    run(select(T.all), from(T), T.id === id && T.uid === userId)
      .query[RNotificationChannelMatrix]
      .option

  def getByAccount(
      userId: Ident
  ): ConnectionIO[Vector[RNotificationChannelMatrix]] = {

    val matrix = as("c")
    Select(
      select(matrix.all),
      from(matrix),
      matrix.uid === userId
    ).build.query[RNotificationChannelMatrix].to[Vector]
  }

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByAccount(id: Ident, userId: Ident): ConnectionIO[Int] =
    DML.delete(
      T,
      T.id === id && T.uid === userId
    )

  def findRefs(ids: NonEmptyList[Ident]): Select =
    Select(
      select(T.id.s, const(ChannelType.Matrix.name), T.name.s),
      from(T),
      T.id.in(ids)
    )
}
