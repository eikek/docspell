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

final case class RAddonRunConfigAddon(
    id: Ident,
    runConfigId: Ident,
    addonId: Ident,
    args: String,
    position: Int
)

object RAddonRunConfigAddon {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "addon_run_config_addon"

    val id = Column[Ident]("id", this)
    val runConfigId = Column[Ident]("addon_run_config_id", this)
    val addonId = Column[Ident]("addon_id", this)
    val args = Column[String]("args", this)
    val position = Column[Int]("position", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, runConfigId, addonId, args, position)
  }

  def as(alias: String): Table = Table(Some(alias))
  val T = Table(None)

  def insert(r: RAddonRunConfigAddon): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id}, ${r.runConfigId}, ${r.addonId}, ${r.args}, ${r.position}"
    )

  def updateArgs(addonTaskId: Ident, addonId: Ident, args: String): ConnectionIO[Int] =
    DML.update(
      T,
      T.runConfigId === addonTaskId && T.addonId === addonId,
      DML.set(
        T.args.setTo(args)
      )
    )

  def findByRunConfig(addonTaskId: Ident): ConnectionIO[List[RAddonRunConfigAddon]] =
    Select(select(T.all), from(T), T.runConfigId === addonTaskId)
      .orderBy(T.position.asc)
      .build
      .query[RAddonRunConfigAddon]
      .to[List]

  def deleteAllForConfig(addonTaskId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.runConfigId === addonTaskId)
}
