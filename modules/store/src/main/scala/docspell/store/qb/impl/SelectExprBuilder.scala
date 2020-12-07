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
        fr"COUNT(*) AS" ++ Fragment.const(alias)

      case SelectExpr.SelectFun(DBFunction.Count(col, alias)) =>
        fr"COUNT(" ++ column(col) ++ fr") AS" ++ Fragment.const(alias)
    }

  def column(col: Column[_]): Fragment = {
    val prefix =
      Fragment.const0(col.table.alias.getOrElse(col.table.tableName))
    prefix ++ Fragment.const0(".") ++ Fragment.const0(col.name)
  }

  def columnNoPrefix(col: Column[_]): Fragment =
    Fragment.const0(col.name)
}
