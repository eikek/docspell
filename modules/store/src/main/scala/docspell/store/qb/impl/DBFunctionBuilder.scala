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

      case DBFunction.Count(col, distinct) =>
        if (distinct) sql"COUNT(DISTINCT " ++ column(col) ++ fr")"
        else sql"COUNT(" ++ column(col) ++ fr")"

      case DBFunction.Max(expr) =>
        sql"MAX(" ++ SelectExprBuilder.build(expr) ++ fr")"

      case DBFunction.Min(expr) =>
        sql"MIN(" ++ SelectExprBuilder.build(expr) ++ fr")"

      case DBFunction.Coalesce(expr, exprs) =>
        val v = exprs.prepended(expr).map(SelectExprBuilder.build)
        sql"COALESCE(" ++ v.reduce(_ ++ comma ++ _) ++ fr")"

      case DBFunction.Power(expr, base) =>
        sql"POWER($base, " ++ SelectExprBuilder.build(expr) ++ fr")"

      case DBFunction.Substring(expr, start, len) =>
        sql"SUBSTRING(" ++ SelectExprBuilder.build(expr) ++ fr" FROM $start FOR $len)"

      case DBFunction.Concat(exprs) =>
        val inner = exprs.map(SelectExprBuilder.build).toList.reduce(_ ++ comma ++ _)
        sql"CONCAT(" ++ inner ++ sql")"

      case DBFunction.Calc(op, left, right) =>
        SelectExprBuilder.build(left) ++
          buildOperator(op) ++
          SelectExprBuilder.build(right)

      case DBFunction.Cast(f, newType) =>
        sql"CAST(" ++ SelectExprBuilder.build(f) ++
          fr" AS" ++ Fragment.const(newType) ++
          sql")"

      case DBFunction.CastNumeric(f) =>
        sql"CAST_TO_NUMERIC(" ++ SelectExprBuilder.build(f) ++ sql")"

      case DBFunction.Avg(expr) =>
        sql"AVG(" ++ SelectExprBuilder.build(expr) ++ fr")"

      case DBFunction.Sum(expr) =>
        sql"SUM(" ++ SelectExprBuilder.build(expr) ++ fr")"
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
