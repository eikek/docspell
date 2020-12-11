package docspell.store.qb.impl

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object FromExprBuilder {

  def build(expr: FromExpr): Fragment =
    expr match {
      case FromExpr.From(table) =>
        fr" FROM" ++ buildTable(table)

      case FromExpr.Joined(from, joins) =>
        build(from) ++
          joins.map(buildJoin).foldLeft(Fragment.empty)(_ ++ _)

      case FromExpr.SubSelect(sel, name) =>
        sql" FROM (" ++ DoobieQuery(sel) ++ fr") AS" ++ Fragment.const(name)
    }

  def buildTable(table: TableDef): Fragment =
    Fragment.const(table.tableName) ++ table.alias
      .map(a => Fragment.const0(a))
      .getOrElse(Fragment.empty)

  def buildJoin(join: Join): Fragment =
    join match {
      case Join.InnerJoin(table, cond) =>
        val c = fr" ON" ++ ConditionBuilder.build(cond)
        fr" INNER JOIN" ++ buildTable(table) ++ c

      case Join.LeftJoin(table, cond) =>
        val c = fr" ON" ++ ConditionBuilder.build(cond)
        fr" LEFT JOIN" ++ buildTable(table) ++ c
    }

}
