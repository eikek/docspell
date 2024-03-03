/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

import cats.data.{NonEmptyList => Nel}
import cats.syntax.option._

import docspell.store.qb.impl.SelectBuilder

import doobie._

/** A sql select statement that allows to change certain parts of the query. */
sealed trait Select {

  /** Builds the sql select statement into a doobie fragment. */
  def build: Fragment =
    SelectBuilder(this)

  /** When using this as a sub-select, an alias is required. */
  def as(alias: String): SelectExpr.SelectQuery =
    SelectExpr.SelectQuery(this, Some(alias))

  def asSubSelect: SelectExpr.SelectQuery =
    SelectExpr.SelectQuery(this, None)

  /** Adds one or more order-by definitions */
  def orderBy(ob: OrderBy, obs: OrderBy*): Select

  /** Uses the given column for ordering asc */
  def orderBy(c: Column[_]): Select =
    orderBy(OrderBy(SelectExpr.SelectColumn(c, None), OrderBy.OrderType.Asc))

  def groupBy(gb: GroupBy): Select

  def groupBy(c: Column[_], cs: Column[_]*): Select =
    groupBy(GroupBy(c, cs: _*))

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

  def withSelect(e: Nel[SelectExpr]): Select

  def changeFrom(f: FromExpr => FromExpr): Select

  def changeWhere(f: Condition => Condition): Select

  def where(c: Option[Condition]): Select =
    where(c.getOrElse(Condition.unit))

  def where(c: Condition): Select

  def unwrap: Select.SimpleSelect
}

object Select {
  def apply(projection: SelectExpr) =
    SimpleSelect(distinctFlag = false, Nel.of(projection), None, Condition.unit, None)

  def apply(projection: Nel[SelectExpr], from: FromExpr) =
    SimpleSelect(distinctFlag = false, projection, from.some, Condition.unit, None)

  def apply(projection: SelectExpr, from: FromExpr) =
    SimpleSelect(
      distinctFlag = false,
      Nel.of(projection),
      from.some,
      Condition.unit,
      None
    )

  def apply(
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(distinctFlag = false, projection, from.some, where, None)

  def apply(
      projection: SelectExpr,
      from: FromExpr,
      where: Condition
  ) = SimpleSelect(distinctFlag = false, Nel.of(projection), from.some, where, None)

  def apply(
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Condition,
      groupBy: GroupBy
  ) = SimpleSelect(distinctFlag = false, projection, from.some, where, Some(groupBy))

  case class SimpleSelect(
      distinctFlag: Boolean,
      projection: Nel[SelectExpr],
      from: Option[FromExpr],
      where: Condition,
      groupBy: Option[GroupBy]
  ) extends Select {
    def unwrap: Select.SimpleSelect =
      this

    def groupBy(gb: GroupBy): SimpleSelect =
      copy(groupBy = Some(gb))

    def distinct: SimpleSelect =
      copy(distinctFlag = true)

    def noDistinct: SimpleSelect =
      copy(distinctFlag = false)

    def where(c: Condition): SimpleSelect =
      copy(where = c)

    def appendSelect(e: SelectExpr): SimpleSelect =
      copy(projection = projection.append(e))

    def withSelect(es: Nel[SelectExpr]): SimpleSelect =
      copy(projection = es)

    def changeFrom(f: FromExpr => FromExpr): SimpleSelect =
      copy(from = from.map(f))

    def changeWhere(f: Condition => Condition): SimpleSelect =
      copy(where = f(where))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(this, ob, obs.toVector)

    def orderBy(ob: Nel[OrderBy]): Ordered =
      Ordered(this, ob.head, ob.tail.toVector)
  }

  case class RawSelect(fragment: Fragment) extends Select {
    def unwrap: Select.SimpleSelect =
      sys.error("Cannot unwrap RawSelect")

    def groupBy(gb: GroupBy): Select =
      sys.error("RawSelect doesn't support adding group by clause")

    def appendSelect(e: SelectExpr): RawSelect =
      sys.error("RawSelect doesn't support appending to select list")

    def changeFrom(f: FromExpr => FromExpr): Select =
      sys.error("RawSelect doesn't support changing from expression")

    def changeWhere(f: Condition => Condition): Select =
      sys.error("RawSelect doesn't support changing where condition")

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      sys.error("RawSelect doesn't support adding orderBy clause")

    def where(c: Condition): Select =
      sys.error("RawSelect doesn't support adding where clause")

    def withSelect(es: Nel[SelectExpr]): Select =
      sys.error("RawSelect doesn't support changing select list")
  }

  case class Union(q: Select, qs: Vector[Select]) extends Select {
    def unwrap: Select.SimpleSelect =
      q.unwrap

    def groupBy(gb: GroupBy): Union =
      copy(q = q.groupBy(gb))

    def appendSelect(e: SelectExpr): Union =
      copy(q = q.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): Union =
      copy(q = q.changeFrom(f))

    def changeWhere(f: Condition => Condition): Union =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(this, ob, obs.toVector)

    def where(c: Condition): Union =
      copy(q = q.where(c))

    def withSelect(es: Nel[SelectExpr]): Union =
      copy(q = q.withSelect(es))
  }

  case class Intersect(q: Select, qs: Vector[Select]) extends Select {
    def unwrap: Select.SimpleSelect =
      q.unwrap

    def groupBy(gb: GroupBy): Intersect =
      copy(q = q.groupBy(gb))

    def appendSelect(e: SelectExpr): Intersect =
      copy(q = q.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): Intersect =
      copy(q = q.changeFrom(f))

    def changeWhere(f: Condition => Condition): Intersect =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(this, ob, obs.toVector)

    def where(c: Condition): Intersect =
      copy(q = q.where(c))

    def withSelect(es: Nel[SelectExpr]): Intersect =
      copy(q = q.withSelect(es))
  }

  case class Ordered(q: Select, orderBy: OrderBy, orderBys: Vector[OrderBy])
      extends Select {
    def unwrap: Select.SimpleSelect =
      q.unwrap

    def groupBy(gb: GroupBy): Ordered =
      copy(q = q.groupBy(gb))

    def appendSelect(e: SelectExpr): Ordered =
      copy(q = q.appendSelect(e))
    def changeFrom(f: FromExpr => FromExpr): Ordered =
      copy(q = q.changeFrom(f))
    def changeWhere(f: Condition => Condition): Ordered =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Ordered =
      Ordered(q, ob, obs.toVector)

    def where(c: Condition): Ordered =
      copy(q = q.where(c))

    def withSelect(es: Nel[SelectExpr]): Ordered =
      copy(q = q.withSelect(es))
  }

  case class Limit(q: Select, batch: Batch) extends Select {
    def unwrap: Select.SimpleSelect =
      q.unwrap

    def groupBy(gb: GroupBy): Limit =
      copy(q = q.groupBy(gb))

    def appendSelect(e: SelectExpr): Limit =
      copy(q = q.appendSelect(e))
    def changeFrom(f: FromExpr => FromExpr): Limit =
      copy(q = q.changeFrom(f))
    def changeWhere(f: Condition => Condition): Limit =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): Limit =
      copy(q = q.orderBy(ob, obs: _*))

    def where(c: Condition): Limit =
      copy(q = q.where(c))

    def withSelect(es: Nel[SelectExpr]): Limit =
      copy(q = q.withSelect(es))
  }

  case class WithCte(cte: CteBind, ctes: Vector[CteBind], q: Select) extends Select {
    def unwrap: Select.SimpleSelect =
      q.unwrap

    def groupBy(gb: GroupBy): WithCte =
      copy(q = q.groupBy(gb))

    def appendSelect(e: SelectExpr): WithCte =
      copy(q = q.appendSelect(e))

    def changeFrom(f: FromExpr => FromExpr): WithCte =
      copy(q = q.changeFrom(f))

    def changeWhere(f: Condition => Condition): WithCte =
      copy(q = q.changeWhere(f))

    def orderBy(ob: OrderBy, obs: OrderBy*): WithCte =
      copy(q = q.orderBy(ob, obs: _*))

    def where(c: Condition): WithCte =
      copy(q = q.where(c))

    def withSelect(es: Nel[SelectExpr]): WithCte =
      copy(q = q.withSelect(es))
  }
}
