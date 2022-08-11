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

case class RClientSettingsCollective(
    id: Ident,
    clientId: Ident,
    cid: CollectiveId,
    settingsData: Json,
    updated: Timestamp,
    created: Timestamp
) {}

object RClientSettingsCollective {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "client_settings_collective"

    val id = Column[Ident]("id", this)
    val clientId = Column[Ident]("client_id", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val settingsData = Column[Json]("settings_data", this)
    val updated = Column[Timestamp]("updated", this)
    val created = Column[Timestamp]("created", this)
    val all =
      NonEmptyList.of[Column[_]](id, clientId, cid, settingsData, updated, created)
  }

  def as(alias: String): Table = Table(Some(alias))
  val T = Table(None)

  def insert(v: RClientSettingsCollective): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      fr"${v.id},${v.clientId},${v.cid},${v.settingsData},${v.updated},${v.created}"
    )
  }

  def updateSettings(
      clientId: Ident,
      cid: CollectiveId,
      data: Json,
      updateTs: Timestamp
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.clientId === clientId && T.cid === cid,
      DML.set(T.settingsData.setTo(data), T.updated.setTo(updateTs))
    )

  def upsert(clientId: Ident, cid: CollectiveId, data: Json): ConnectionIO[Int] =
    for {
      id <- Ident.randomId[ConnectionIO]
      now <- Timestamp.current[ConnectionIO]
      nup <- updateSettings(clientId, cid, data, now)
      nin <-
        if (nup <= 0) insert(RClientSettingsCollective(id, clientId, cid, data, now, now))
        else 0.pure[ConnectionIO]
    } yield nup + nin

  def delete(clientId: Ident, cid: CollectiveId): ConnectionIO[Int] =
    DML.delete(T, T.clientId === clientId && T.cid === cid)

  def find(
      clientId: Ident,
      cid: CollectiveId
  ): ConnectionIO[Option[RClientSettingsCollective]] =
    run(select(T.all), from(T), T.clientId === clientId && T.cid === cid)
      .query[RClientSettingsCollective]
      .option
}
