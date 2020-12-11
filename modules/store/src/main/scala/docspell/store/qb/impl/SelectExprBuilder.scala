package docspell.store.qb.impl

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object SelectExprBuilder {

  def build(expr: SelectExpr): Fragment =
    expr match {
      case SelectExpr.SelectColumn(col) =>
        column(col)

      case SelectExpr.SelectFun(DBFunction.CountAll(alias)) =>
        sql"COUNT(*) AS" ++ Fragment.const(alias)

      case SelectExpr.SelectFun(DBFunction.Count(col, alias)) =>
        sql"COUNT(" ++ column(col) ++ fr") AS" ++ Fragment.const(alias)

      case SelectExpr.SelectFun(DBFunction.Max(col, alias)) =>
        sql"MAX(" ++ column(col) ++ fr") AS" ++ Fragment.const(alias)
    }

  def column(col: Column[_]): Fragment = {
    val prefix = col.table.alias.getOrElse(col.table.tableName)
    if (prefix.isEmpty) columnNoPrefix(col)
    else Fragment.const0(prefix) ++ Fragment.const0(".") ++ Fragment.const0(col.name)
  }

  def columnNoPrefix(col: Column[_]): Fragment =
    Fragment.const0(col.name)
}
