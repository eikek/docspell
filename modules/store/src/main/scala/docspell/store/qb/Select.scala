package docspell.store.qb

import cats.data.{NonEmptyList => Nel}

import docspell.store.qb.impl.SelectBuilder

import doobie._

sealed trait Select {
  def build: Fragment =
    SelectBuilder(this)

  def as(alias: String): SelectExpr.SelectQuery =
    SelectExpr.SelectQuery(this, Some(alias))

  def orderBy(ob: OrderBy, obs: OrderBy*): Select.Ordered =
    Select.Ordered(this, ob, obs.toVector)

  def orderBy(c: Column[_]): Select.Ordered =
    orderBy(OrderBy(SelectExpr.SelectColumn(c, None), OrderBy.OrderType.Asc))

  def limit(n: Int): Select =
    this match {
      case Select.Limit(q, _) =>
        Select.Limit(q, n)
      case _ =>
        Select.Limit(this, n)
    }

  def appendCte(next: CteBind): Select =
    this match {
      case Select.WithCte(cte, ctes, query) =>
        Select.WithCte(cte, ctes :+ next, query)
      case _ =>
        Select.WithCte(next, Vector.empty, this)
    }

  def appendSelect(e: SelectExpr): Select
}

object Select {
  def apply(projection: Nel[SelectExpr], from: FromExpr) =
    SimpleSelect(false, projection, from, None, None)

  def apply(projection: SelectExpr, from: FromExpr) =
    SimpleSelect(false, Nel.of(projection), from, None, None)

  def apply(
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(false, projection, from, Some(where), None)

  def apply(
      projection: SelectExpr,
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(false, Nel.of(projection), from, Some(where), None)

  def apply(
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Condition,
      groupBy: GroupBy
  ) = SimpleSelect(false, projection, from, Some(where), Some(groupBy))

  case class SimpleSelect(
      distinctFlag: Boolean,
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Option[Condition],
      groupBy: Option[GroupBy]
  ) extends Select {
    def group(gb: GroupBy): SimpleSelect =
      copy(groupBy = Some(gb))

    def distinct: SimpleSelect =
      copy(distinctFlag = true)

    def where(c: Option[Condition]): SimpleSelect =
      copy(where = c)
    def where(c: Condition): SimpleSelect =
      copy(where = Some(c))

    def appendSelect(e: SelectExpr): SimpleSelect =
      copy(projection = projection.append(e))
  }

  case class RawSelect(fragment: Fragment) extends Select {
    def appendSelect(e: SelectExpr): RawSelect =
      sys.error("RawSelect doesn't support appending select expressions")
  }

  case class Union(q: Select, qs: Vector[Select]) extends Select {
    def appendSelect(e: SelectExpr): Union =
      copy(q = q.appendSelect(e))
  }

  case class Intersect(q: Select, qs: Vector[Select]) extends Select {
    def appendSelect(e: SelectExpr): Intersect =
      copy(q = q.appendSelect(e))
  }

  case class Ordered(q: Select, orderBy: OrderBy, orderBys: Vector[OrderBy])
      extends Select {
    def appendSelect(e: SelectExpr): Ordered =
      copy(q = q.appendSelect(e))
  }

  case class Limit(q: Select, limit: Int) extends Select {
    def appendSelect(e: SelectExpr): Limit =
      copy(q = q.appendSelect(e))
  }

  case class WithCte(cte: CteBind, ctes: Vector[CteBind], query: Select) extends Select {
    def appendSelect(e: SelectExpr): WithCte =
      copy(query = query.appendSelect(e))
  }
}
