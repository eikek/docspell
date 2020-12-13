package docspell.store.qb.impl

import docspell.store.qb.DBFunction

import doobie._
import doobie.implicits._

object DBFunctionBuilder extends CommonBuilder {
  private val comma = fr","

  def build(expr: DBFunction): Fragment =
    expr match {
      case DBFunction.CountAll =>
        sql"COUNT(*)"

      case DBFunction.Count(col) =>
        sql"COUNT(" ++ column(col) ++ fr")"

      case DBFunction.Max(col) =>
        sql"MAX(" ++ column(col) ++ fr")"

      case DBFunction.Min(col) =>
        sql"MIN(" ++ column(col) ++ fr")"

      case DBFunction.Coalesce(expr, exprs) =>
        val v = exprs.prepended(expr).map(SelectExprBuilder.build)
        sql"COALESCE(" ++ v.reduce(_ ++ comma ++ _) ++ fr")"

      case DBFunction.Power(expr, base) =>
        sql"POWER($base, " ++ SelectExprBuilder.build(expr) ++ fr")"

      case DBFunction.Calc(op, left, right) =>
        SelectExprBuilder.build(left) ++
          buildOperator(op) ++
          SelectExprBuilder.build(right)

    }

  def buildOperator(op: DBFunction.Operator): Fragment =
    op match {
      case DBFunction.Operator.Minus =>
        fr" -"
      case DBFunction.Operator.Plus =>
        fr" +"
      case DBFunction.Operator.Mult =>
        fr" *"
    }
}
