package docspell.store.qb.impl

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object DoobieQuery {
  val comma     = fr","
  val asc       = fr" ASC"
  val desc      = fr" DESC"
  val intersect = fr"INTERSECT"
  val union     = fr"UNION ALL"

  def apply(q: Select): Fragment =
    build(false)(q)

  def distinct(q: Select): Fragment =
    build(true)(q)

  def build(distinct: Boolean)(q: Select): Fragment =
    q match {
      case sq: Select.SimpleSelect =>
        val sel = if (distinct) fr"SELECT DISTINCT" else fr"SELECT"
        sel ++ buildSimple(sq)

      case Select.Union(q, qs) =>
        qs.prepended(q).map(build(false)).reduce(_ ++ union ++ _)

      case Select.Intersect(q, qs) =>
        qs.prepended(q).map(build(false)).reduce(_ ++ intersect ++ _)

      case Select.Ordered(q, ob, obs) =>
        val order = obs.prepended(ob).map(orderBy).reduce(_ ++ comma ++ _)
        build(distinct)(q) ++ fr"ORDER BY" ++ order

      case Select.Limit(q, n) =>
        build(distinct)(q) ++ fr" LIMIT $n"
    }

  def buildSimple(sq: Select.SimpleSelect): Fragment = {
    val f0 = sq.projection.map(selectExpr).reduce(_ ++ comma ++ _)
    val f1 = fromExpr(sq.from)
    val f2 = sq.where.map(cond).getOrElse(Fragment.empty)
    val f3 = sq.groupBy.map(groupBy).getOrElse(Fragment.empty)
    f0 ++ f1 ++ f2 ++ f3
  }

  def orderBy(ob: OrderBy): Fragment = {
    val f1 = selectExpr(ob.expr)
    val f2 = ob.orderType match {
      case OrderBy.OrderType.Asc =>
        asc
      case OrderBy.OrderType.Desc =>
        desc
    }
    f1 ++ f2
  }

  def selectExpr(se: SelectExpr): Fragment =
    SelectExprBuilder.build(se)

  def fromExpr(fr: FromExpr): Fragment =
    FromExprBuilder.build(fr)

  def cond(c: Condition): Fragment =
    fr" WHERE" ++ ConditionBuilder.build(c)

  def groupBy(gb: GroupBy): Fragment = {
    val f0 = gb.names.prepended(gb.name).map(selectExpr).reduce(_ ++ comma ++ _)
    val f1 = gb.having.map(cond).getOrElse(Fragment.empty)
    fr"GROUP BY" ++ f0 ++ f1
  }
}
