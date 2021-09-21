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
import docspell.store.qb._

import doobie._
import doobie.implicits._
import io.circe.Json

case class RClientSettings(
    id: Ident,
    clientId: Ident,
    userId: Ident,
    settingsData: Json,
    updated: Timestamp,
    created: Timestamp
) {}

object RClientSettings {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "client_settings"

    val id           = Column[Ident]("id", this)
    val clientId     = Column[Ident]("client_id", this)
    val userId       = Column[Ident]("user_id", this)
    val settingsData = Column[Json]("settings_data", this)
    val updated      = Column[Timestamp]("updated", this)
    val created      = Column[Timestamp]("created", this)
    val all =
      NonEmptyList.of[Column[_]](id, clientId, userId, settingsData, updated, created)
  }

  def as(alias: String): Table = Table(Some(alias))
  val T                        = Table(None)

  def insert(v: RClientSettings): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      fr"${v.id},${v.clientId},${v.userId},${v.settingsData},${v.updated},${v.created}"
    )
  }

  def updateSettings(
      clientId: Ident,
      userId: Ident,
      data: Json,
      updateTs: Timestamp
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.clientId === clientId && T.userId === userId,
      DML.set(T.settingsData.setTo(data), T.updated.setTo(updateTs))
    )

  def upsert(clientId: Ident, userId: Ident, data: Json): ConnectionIO[Int] =
    for {
      id  <- Ident.randomId[ConnectionIO]
      now <- Timestamp.current[ConnectionIO]
      nup <- updateSettings(clientId, userId, data, now)
      nin <-
        if (nup <= 0) insert(RClientSettings(id, clientId, userId, data, now, now))
        else 0.pure[ConnectionIO]
    } yield nup + nin

  def delete(clientId: Ident, userId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.clientId === clientId && T.userId === userId)

  def find(clientId: Ident, userId: Ident): ConnectionIO[Option[RClientSettings]] =
    run(select(T.all), from(T), T.clientId === clientId && T.userId === userId)
      .query[RClientSettings]
      .option
}
