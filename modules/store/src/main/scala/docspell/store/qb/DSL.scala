package docspell.store.qb

import cats.data.{NonEmptyList => Nel}

import docspell.store.impl.DoobieMeta
import docspell.store.qb.impl.SelectBuilder

import doobie.{Fragment, Put}

trait DSL extends DoobieMeta {

  def run(projection: Nel[SelectExpr], from: FromExpr): Fragment =
    SelectBuilder(Select(projection, from))

  def run(projection: Nel[SelectExpr], from: FromExpr, where: Condition): Fragment =
    SelectBuilder(Select(projection, from, where))

  def runDistinct(
      projection: Nel[SelectExpr],
      from: FromExpr,
      where: Condition
  ): Fragment =
    SelectBuilder(Select(projection, from, where).distinct)

  def withCte(cte: (TableDef, Select), more: (TableDef, Select)*): DSL.WithCteDsl =
    DSL.WithCteDsl(CteBind(cte), more.map(CteBind.apply).toVector)

  def select(cond: Condition): Nel[SelectExpr] =
    Nel.of(SelectExpr.SelectCondition(cond, None))

  def select(dbf: DBFunction): Nel[SelectExpr] =
    Nel.of(SelectExpr.SelectFun(dbf, None))

  def select(e: SelectExpr, es: SelectExpr*): Nel[SelectExpr] =
    Nel(e, es.toList)

  def select(c: Column[_], cs: Column[_]*): Nel[SelectExpr] =
    Nel(c, cs.toList).map(col => SelectExpr.SelectColumn(col, None))

  def select(seq: Nel[Column[_]], seqs: Nel[Column[_]]*): Nel[SelectExpr] =
    seqs.foldLeft(seq)(_ concatNel _).map(c => SelectExpr.SelectColumn(c, None))

  def union(s1: Select, sn: Select*): Select =
    Select.Union(s1, sn.toVector)

  def intersect(s1: Select, sn: Select*): Select =
    Select.Intersect(s1, sn.toVector)

  def intersect(nel: Nel[Select]): Select =
    Select.Intersect(nel.head, nel.tail.toVector)

  def from(table: TableDef): FromExpr.From =
    FromExpr.From(table)

  def fromSubSelect(sel: Select): FromExpr.SubSelect =
    FromExpr.SubSelect(sel, "x")

  def count(c: Column[_]): DBFunction =
    DBFunction.Count(c)

  def countAll: DBFunction =
    DBFunction.CountAll

  def max(c: Column[_]): DBFunction =
    DBFunction.Max(c)

  def min(c: Column[_]): DBFunction =
    DBFunction.Min(c)

  def coalesce(expr: SelectExpr, more: SelectExpr*): DBFunction.Coalesce =
    DBFunction.Coalesce(expr, more.toVector)

  def power(base: Int, expr: SelectExpr): DBFunction =
    DBFunction.Power(expr, base)

  def lit[A](value: A)(implicit P: Put[A]): SelectExpr.SelectLit[A] =
    SelectExpr.SelectLit(value, None)

  def plus(left: SelectExpr, right: SelectExpr): DBFunction =
    DBFunction.Calc(DBFunction.Operator.Plus, left, right)

  def mult(left: SelectExpr, right: SelectExpr): DBFunction =
    DBFunction.Calc(DBFunction.Operator.Mult, left, right)

  def and(c: Condition, cs: Condition*): Condition =
    c match {
      case Condition.And(head, tail) =>
        Condition.And(head, tail ++ (c +: cs.toVector))
      case _ =>
        Condition.And(c, cs.toVector)
    }

  def or(c: Condition, cs: Condition*): Condition =
    c match {
      case Condition.Or(head, tail) =>
        Condition.Or(head, tail ++ (c +: cs.toVector))
      case _ =>
        Condition.Or(c, cs.toVector)
    }

  def not(c: Condition): Condition =
    c match {
      case Condition.Not(el) =>
        el
      case _ =>
        Condition.Not(c)
    }

  def where(c: Condition, cs: Condition*): Condition =
    if (cs.isEmpty) c
    else and(c, cs: _*)

  implicit final class ColumnOps[A](col: Column[A]) {
    def s: SelectExpr =
      SelectExpr.SelectColumn(col, None)
    def as(alias: String): SelectExpr =
      SelectExpr.SelectColumn(col, Some(alias))
    def as(otherCol: Column[A]): SelectExpr =
      SelectExpr.SelectColumn(col, Some(otherCol.name))

    def setTo(value: A)(implicit P: Put[A]): Setter[A] =
      Setter.SetValue(col, value)

    def setTo(value: Option[A])(implicit P: Put[A]): Setter[Option[A]] =
      Setter.SetOptValue(col, value)

    def increment(amount: Int): Setter[A] =
      Setter.Increment(col, amount)

    def asc: OrderBy =
      OrderBy(SelectExpr.SelectColumn(col, None), OrderBy.OrderType.Asc)

    def desc: OrderBy =
      OrderBy(SelectExpr.SelectColumn(col, None), OrderBy.OrderType.Desc)

    def ===(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Eq, value)

    def ====(value: String): Condition =
      Condition.CompareVal(col.asInstanceOf[Column[String]], Operator.Eq, value)

    def like(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.LowerLike, value)

    def likes(value: String): Condition =
      Condition.CompareVal(col.asInstanceOf[Column[String]], Operator.LowerLike, value)

    def <=(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Lte, value)

    def >=(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Gte, value)

    def >(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Gt, value)

    def <(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Lt, value)

    def <>(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Neq, value)

    def in(subsel: Select): Condition =
      Condition.InSubSelect(col, subsel)

    def in(values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col, values, false)

    def inLower(values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col, values, true)

    def isNull: Condition =
      Condition.IsNull(col)

    def isNotNull: Condition =
      Condition.IsNull(col).negate

    def ===(other: Column[A]): Condition =
      Condition.CompareCol(col, Operator.Eq, other)
  }

  implicit final class ConditionOps(c: Condition) {
    def s: SelectExpr =
      SelectExpr.SelectCondition(c, None)

    def as(alias: String): SelectExpr =
      SelectExpr.SelectCondition(c, Some(alias))

    def &&(other: Condition): Condition =
      and(c, other)

    def &&?(other: Option[Condition]): Condition =
      other.map(ce => &&(ce)).getOrElse(c)

    def ||(other: Condition): Condition =
      or(c, other)

    def ||?(other: Option[Condition]): Condition =
      other.map(ce => ||(ce)).getOrElse(c)

    def negate: Condition =
      not(c)

    def unary_! : Condition =
      not(c)
  }

  implicit final class DBFunctionOps(dbf: DBFunction) {
    def s: SelectExpr =
      SelectExpr.SelectFun(dbf, None)
    def as(alias: String): SelectExpr =
      SelectExpr.SelectFun(dbf, Some(alias))

    def ===[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Eq, value)

    def ====(value: String): Condition =
      Condition.CompareFVal(dbf, Operator.Eq, value)

    def like[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.LowerLike, value)

    def likes(value: String): Condition =
      Condition.CompareFVal(dbf, Operator.LowerLike, value)

    def <=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Lte, value)

    def >=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Gte, value)

    def >[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Gt, value)

    def <[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Lt, value)

    def <>[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf, Operator.Neq, value)

    def -[A](value: A)(implicit P: Put[A]): DBFunction =
      DBFunction.Calc(
        DBFunction.Operator.Minus,
        SelectExpr.SelectFun(dbf, None),
        SelectExpr.SelectLit(value, None)
      )
  }
}

object DSL extends DSL {

  final case class WithCteDsl(cte: CteBind, ctes: Vector[CteBind]) {

    def select(s: Select): Select.WithCte =
      Select.WithCte(cte, ctes, s)

    def apply(s: Select): Select.WithCte =
      select(s)
  }

}
