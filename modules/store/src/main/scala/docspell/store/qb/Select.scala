package docspell.store.qb

import docspell.store.qb.impl.DoobieQuery

import doobie._

sealed trait Select {
  def distinct: Fragment =
    DoobieQuery.distinct(this)

  def run: Fragment =
    DoobieQuery(this)

  def orderBy(ob: OrderBy, obs: OrderBy*): Select.Ordered =
    Select.Ordered(this, ob, obs.toVector)

  def orderBy(c: Column[_]): Select.Ordered =
    orderBy(OrderBy(SelectExpr.SelectColumn(c, None), OrderBy.OrderType.Asc))

  def limit(n: Int): Select =
    this match {
      case Select.Limit(q, _) => Select.Limit(q, n)
      case _ =>
        Select.Limit(this, n)
    }
}

object Select {

  def apply(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(projection, from, Some(where), None)

  def apply(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Option[Condition] = None,
      groupBy: Option[GroupBy] = None
  ) = SimpleSelect(projection, from, where, groupBy)

  case class SimpleSelect(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Option[Condition],
      groupBy: Option[GroupBy]
  ) extends Select {
    def group(gb: GroupBy): SimpleSelect =
      copy(groupBy = Some(gb))
  }

  case class Union(q: Select, qs: Vector[Select]) extends Select

  case class Intersect(q: Select, qs: Vector[Select]) extends Select

  case class Ordered(q: Select, orderBy: OrderBy, orderBys: Vector[OrderBy])
      extends Select

  case class Limit(q: Select, limit: Int) extends Select
}
