/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

trait TableDef {
  def tableName: String

  def alias: Option[String]
}

object TableDef {

  def apply(table: String, aliasName: Option[String] = None): BasicTable =
    BasicTable(table, aliasName)

  final case class BasicTable(tableName: String, alias: Option[String]) extends TableDef {
    def as(alias: String): BasicTable =
      copy(alias = Some(alias))
  }

}
