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
        sql"COALESCE(" ++ v.reduce(_ ++ comma ++ _) ++ sql")"

      case DBFunction.Power(expr, base) =>
        sql"POWER($base, " ++ SelectExprBuilder.build(expr) ++ sql")"

      case DBFunction.Plus(expr, more) =>
        val v = more.prepended(expr).map(SelectExprBuilder.build)
        v.reduce(_ ++ fr" +" ++ _)

      case DBFunction.Mult(expr, more) =>
        val v = more.prepended(expr).map(SelectExprBuilder.build)
        v.reduce(_ ++ fr" *" ++ _)
    }
}
