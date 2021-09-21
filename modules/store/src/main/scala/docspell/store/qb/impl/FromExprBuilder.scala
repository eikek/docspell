/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.impl

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object FromExprBuilder {

  def build(expr: FromExpr): Fragment =
    expr match {
      case FromExpr.From(relation) =>
        fr" FROM" ++ buildRelation(relation)

      case FromExpr.Joined(from, joins) =>
        build(from) ++
          joins.map(buildJoin).foldLeft(Fragment.empty)(_ ++ _)
    }

  def buildTable(table: TableDef): Fragment =
    Fragment.const(table.tableName) ++ table.alias
      .map(a => Fragment.const0(a))
      .getOrElse(Fragment.empty)

  def buildRelation(rel: FromExpr.Relation): Fragment =
    rel match {
      case FromExpr.Relation.Table(table) =>
        buildTable(table)

      case FromExpr.Relation.SubSelect(sel, alias) =>
        sql" (" ++ SelectBuilder(sel) ++ fr") AS" ++ Fragment.const(alias)
    }

  def buildJoin(join: FromExpr.Join): Fragment =
    join match {
      case FromExpr.Join.InnerJoin(table, cond) =>
        val c = fr" ON" ++ ConditionBuilder.build(cond)
        fr" INNER JOIN" ++ buildRelation(table) ++ c

      case FromExpr.Join.LeftJoin(table, cond) =>
        val c = fr" ON" ++ ConditionBuilder.build(cond)
        fr" LEFT JOIN" ++ buildRelation(table) ++ c
    }

}
