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

final case class RAddonRunConfigTrigger(
    id: Ident,
    runConfigId: Ident,
    trigger: AddonTriggerType
)

object RAddonRunConfigTrigger {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "addon_run_config_trigger"

    val id = Column[Ident]("id", this)
    val runConfigId = Column[Ident]("addon_run_config_id", this)
    val trigger = Column[AddonTriggerType]("triggers", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, runConfigId, trigger)
  }

  def as(alias: String): Table = Table(Some(alias))
  val T = Table(None)

  def deleteAllForConfig(addonTaskId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.runConfigId === addonTaskId)

  def insert(r: RAddonRunConfigTrigger): ConnectionIO[Int] =
    DML.insert(T, T.all, sql"${r.id}, ${r.runConfigId}, ${r.trigger}")

  def insertAll(
      addonTaskId: Ident,
      triggers: NonEmptyList[AddonTriggerType]
  ): ConnectionIO[Int] = {
    val records = triggers.traverse(t =>
      Ident.randomId[ConnectionIO].map(id => RAddonRunConfigTrigger(id, addonTaskId, t))
    )
    val inserts =
      s"INSERT INTO ${T.tableName} (id, addon_run_config_id, trigger) VALUES (?,?,?)"
    records.flatMap(rs => Update[RAddonRunConfigTrigger](inserts).updateMany(rs))
  }

  def findByRunConfig(addonTaskId: Ident): ConnectionIO[List[RAddonRunConfigTrigger]] =
    Select(select(T.all), from(T), T.runConfigId === addonTaskId).build
      .query[RAddonRunConfigTrigger]
      .to[List]
}
