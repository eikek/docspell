package docspell.store.qb

import docspell.store.qb.impl.SelectBuilder

import doobie._

sealed trait Select {
  def run: Fragment =
    SelectBuilder(this)

  def as(alias: String): SelectExpr.SelectQuery =
    SelectExpr.SelectQuery(this, Some(alias))

  def orderBy(ob: OrderBy, obs: OrderBy*): Select.Ordered =
    Select.Ordered(this, ob, obs.toVector)

  def orderBy(c: Column[_]): Select.Ordered =
    orderBy(OrderBy(SelectExpr.SelectColumn(c, None), OrderBy.OrderType.Asc))

  def limit(n: Int): Select =
    this match {
      case Select.Limit(q, _) => Select.Limit(q, n)
      case _                  => Select.Limit(this, n)
    }
}

object Select {
  def apply(projection: Seq[SelectExpr], from: FromExpr) =
    SimpleSelect(false, projection, from, None, None)

  def apply(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(false, projection, from, Some(where), None)

  def apply(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Condition,
      groupBy: GroupBy
  ) = SimpleSelect(false, projection, from, Some(where), Some(groupBy))

  case class SimpleSelect(
      distinctFlag: Boolean,
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Option[Condition],
      groupBy: Option[GroupBy]
  ) extends Select {
    def group(gb: GroupBy): SimpleSelect =
      copy(groupBy = Some(gb))

    def distinct: SimpleSelect =
      copy(distinctFlag = true)
  }

  case class Union(q: Select, qs: Vector[Select]) extends Select

  case class Intersect(q: Select, qs: Vector[Select]) extends Select

  case class Ordered(q: Select, orderBy: OrderBy, orderBys: Vector[OrderBy])
      extends Select

  case class Limit(q: Select, limit: Int) extends Select

  case class WithCte(cte: CteBind, ctes: Vector[CteBind], query: Select) extends Select
}
