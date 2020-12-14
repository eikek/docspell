package docspell.store.qb

import cats.data.{NonEmptyList => Nel}

import docspell.store.qb.impl.SelectBuilder

import doobie._

sealed trait Select {
  def build: Fragment =
    SelectBuilder(this)

  def as(alias: String): SelectExpr.SelectQuery =
    SelectExpr.SelectQuery(this, Some(alias))

  def orderBy(ob: OrderBy, obs: OrderBy*): Select

  def orderBy(c: Column[_]): Select =
    orderBy(OrderBy(SelectExpr.SelectColumn(c, None), OrderBy.OrderType.Asc))

  def limit(batch: Batch): Select =
    this match {
      case Select.Limit(q, _) =>
        Select.Limit(q, batch)
      case _ =>
        Select.Limit(this, batch)
    }

  def limit(n: Int): Select =
    limit(Batch.limit(n))

  def appendCte(next: CteBind): Select =
    this match {
      case Select.WithCte(cte, ctes, query) =>
        Select.WithCte(cte, ctes :+ next, query)
      case _ =>
        Select.WithCte(next, Vector.empty, this)
    }

  def appendSelect(e: SelectExpr): Select

  def changeFrom(f: FromExpr => FromExpr): Select

  def changeWhere(f: Condition => Condition): Select
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

    def changeFrom(f: FromExpr => FromExpr): SimpleSelect =
      copy(from = f(from))

    def changeWhere(f: Condition => Condition): SimpleSelect =
      copy(where = where.map(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Select =
      Ordered(this, ob, obs.toVector)
  }

  case class RawSelect(fragment: Fragment) extends Select {
    def appendSelect(e: SelectExpr): RawSelect =
      sys.error("RawSelect doesn't support appending select expressions")

    def changeFrom(f: FromExpr => FromExpr): Select =
      sys.error("RawSelect doesn't support changing from expression")

    def changeWhere(f: Condition => Condition): Select =
      sys.error("RawSelect doesn't support changing where condition")

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      sys.error("RawSelect doesn't support adding orderBy clause")
  }

  case class Union(q: Select, qs: Vector[Select]) extends Select {
    def appendSelect(e: SelectExpr): Union =
      copy(q = q.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): Union =
      copy(q = q.changeFrom(f))

    def changeWhere(f: Condition => Condition): Union =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(this, ob, obs.toVector)
  }

  case class Intersect(q: Select, qs: Vector[Select]) extends Select {
    def appendSelect(e: SelectExpr): Intersect =
      copy(q = q.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): Intersect =
      copy(q = q.changeFrom(f))

    def changeWhere(f: Condition => Condition): Intersect =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(this, ob, obs.toVector)
  }

  case class Ordered(q: Select, orderBy: OrderBy, orderBys: Vector[OrderBy])
      extends Select {
    def appendSelect(e: SelectExpr): Ordered =
      copy(q = q.appendSelect(e))
    def changeFrom(f: FromExpr => FromExpr): Ordered =
      copy(q = q.changeFrom(f))
    def changeWhere(f: Condition => Condition): Ordered =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(q, ob, obs.toVector)
  }

  case class Limit(q: Select, batch: Batch) extends Select {
    def appendSelect(e: SelectExpr): Limit =
      copy(q = q.appendSelect(e))
    def changeFrom(f: FromExpr => FromExpr): Limit =
      copy(q = q.changeFrom(f))
    def changeWhere(f: Condition => Condition): Limit =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Limit =
      copy(q = q.orderBy(ob, obs: _*))

  }

  case class WithCte(cte: CteBind, ctes: Vector[CteBind], query: Select) extends Select {
    def appendSelect(e: SelectExpr): WithCte =
      copy(query = query.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): WithCte =
      copy(query = query.changeFrom(f))

    def changeWhere(f: Condition => Condition): WithCte =
      copy(query = query.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): WithCte =
      copy(query = query.orderBy(ob, obs: _*))
  }
}
