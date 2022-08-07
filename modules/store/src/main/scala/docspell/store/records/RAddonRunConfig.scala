/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.addons.AddonTriggerType
import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RAddonRunConfig(
    id: Ident,
    cid: CollectiveId,
    userId: Option[Ident],
    name: String,
    enabled: Boolean,
    created: Timestamp
)

object RAddonRunConfig {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "addon_run_config"

    val id = Column[Ident]("id", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val userId = Column[Ident]("user_id", this)
    val name = Column[String]("name", this)
    val enabled = Column[Boolean]("enabled", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, cid, userId, name, enabled, created)
  }

  def as(alias: String): Table = Table(Some(alias))
  val T = Table(None)

  def insert(r: RAddonRunConfig): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id}, ${r.cid}, ${r.userId}, ${r.name}, ${r.enabled}, ${r.created}"
    )

  def update(r: RAddonRunConfig): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id,
      DML.set(
        T.name.setTo(r.name),
        T.enabled.setTo(r.enabled),
        T.userId.setTo(r.userId)
      )
    )

  def findById(cid: CollectiveId, id: Ident): ConnectionIO[Option[RAddonRunConfig]] =
    Select(select(T.all), from(T), T.cid === cid && T.id === id).build
      .query[RAddonRunConfig]
      .option

  def findByCollective(
      cid: CollectiveId,
      enabled: Option[Boolean],
      trigger: Set[AddonTriggerType],
      configIds: Set[Ident]
  ): ConnectionIO[List[RAddonRunConfig]] = {
    val ac = RAddonRunConfig.as("ac")
    val tt = RAddonRunConfigTrigger.as("tt")
    val filter =
      ac.cid === cid &&?
        enabled.map(e => ac.enabled === e) &&?
        NonEmptyList.fromList(configIds.toList).map(ids => ac.id.in(ids))

    val selectConfigs =
      NonEmptyList.fromList(trigger.toList) match {
        case Some(tri) =>
          Select(
            select(ac.all),
            from(ac).innerJoin(tt, tt.runConfigId === ac.id),
            filter && tt.trigger.in(tri)
          )
        case None =>
          Select(select(ac.all), from(ac), filter)
      }

    selectConfigs.build.query[RAddonRunConfig].to[List]
  }

  def deleteById(cid: CollectiveId, id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === cid && T.id === id)
}
