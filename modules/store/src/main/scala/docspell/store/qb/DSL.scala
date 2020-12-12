package docspell.store.qb

import cats.data.NonEmptyList

import docspell.store.impl.DoobieMeta
import docspell.store.qb.impl.DoobieQuery

import doobie.{Fragment, Put}

trait DSL extends DoobieMeta {

  def run(projection: Seq[SelectExpr], from: FromExpr): Fragment =
    DoobieQuery(Select(projection, from, None))

  def run(projection: Seq[SelectExpr], from: FromExpr, where: Condition): Fragment =
    DoobieQuery(Select(projection, from, where))

  def runDistinct(
      projection: Seq[SelectExpr],
      from: FromExpr,
      where: Condition
  ): Fragment =
    DoobieQuery.distinct(Select(projection, from, where))

  def select(dbf: DBFunction): Seq[SelectExpr] =
    Seq(SelectExpr.SelectFun(dbf, None))

  def select(c: Column[_], cs: Column[_]*): Seq[SelectExpr] =
    select(c :: cs.toList)

  def select(seq: Seq[Column[_]], seqs: Seq[Column[_]]*): Seq[SelectExpr] =
    (seq ++ seqs.flatten).map(c => SelectExpr.SelectColumn(c, None))

  def union(s1: Select, sn: Select*): Select =
    Select.Union(s1, sn.toVector)

  def from(table: TableDef): FromExpr.From =
    FromExpr.From(table)

  def fromSubSelect(sel: Select): FromExpr.SubSelect =
    FromExpr.SubSelect(sel, "x")

  def count(c: Column[_]): DBFunction =
    DBFunction.Count(c)

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

  def plus(expr: SelectExpr, more: SelectExpr*): DBFunction =
    DBFunction.Plus(expr, more.toVector)

  def mult(expr: SelectExpr, more: SelectExpr*): DBFunction =
    DBFunction.Mult(expr, more.toVector)

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
    def s: SelectExpr     = SelectExpr.SelectColumn(col, None)
    def as(alias: String) = SelectExpr.SelectColumn(col, Some(alias))

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

    def in(values: NonEmptyList[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col, values, false)

    def inLower(values: NonEmptyList[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col, values, true)

    def isNull: Condition =
      Condition.IsNull(col)

    def ===(other: Column[A]): Condition =
      Condition.CompareCol(col, Operator.Eq, other)
  }

  implicit final class ConditionOps(c: Condition) {

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
    def s: SelectExpr     = SelectExpr.SelectFun(dbf, None)
    def as(alias: String) = SelectExpr.SelectFun(dbf, Some(alias))

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
  }

}

object DSL extends DSL
