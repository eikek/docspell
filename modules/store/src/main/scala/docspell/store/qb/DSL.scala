/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

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

  def withCte(
      name: TableDef,
      col: Column[_],
      cols: Column[_]*
  ): Select => DSL.WithCteDsl =
    sel => DSL.WithCteDsl(CteBind(name, col, cols: _*)(sel), Vector.empty)

  def select(cond: Condition): Nel[SelectExpr] =
    Nel.of(SelectExpr.SelectCondition(cond, None))

  def select(dbf: DBFunction): Nel[SelectExpr] =
    Nel.of(SelectExpr.SelectFun(dbf, None))

  def select(e: SelectExpr, es: SelectExpr*): Nel[SelectExpr] =
    Nel(e, es.toList)

  def combineNel[A](e: Nel[A], more: Nel[A]*): Nel[A] =
    Nel
      .fromFoldable(more)
      .map(tail => tail.prepend(e).flatMap(identity))
      .getOrElse(e)

  def select(c: Column[_], cs: Column[_]*): Nel[SelectExpr] =
    Nel(c, cs.toList).map(col => SelectExpr.SelectColumn(col, None))

  def select(seq: Nel[Column[_]], seqs: Nel[Column[_]]*): Nel[SelectExpr] =
    seqs.foldLeft(seq)(_ concatNel _).map(c => SelectExpr.SelectColumn(c, None))

  def union(s1: Select, sn: Select*): Select =
    Select.Union(s1, sn.toVector)

  def union(selects: Nel[Select]): Select =
    Select.Union(selects.head, selects.tail.toVector)

  def intersect(s1: Select, sn: Select*): Select =
    Select.Intersect(s1, sn.toVector)

  def intersect(nel: Nel[Select]): Select =
    Select.Intersect(nel.head, nel.tail.toVector)

  def from(table: TableDef): FromExpr.From =
    FromExpr.From(table)

  def from(sel: Select, alias: String): FromExpr.From =
    FromExpr.From(sel, alias)

  def count(c: Column[_]): DBFunction =
    DBFunction.Count(c, distinct = false)

  def countDistinct(c: Column[_]): DBFunction =
    DBFunction.Count(c, distinct = true)

  def countAll: DBFunction =
    DBFunction.CountAll

  def max(e: SelectExpr): DBFunction =
    DBFunction.Max(e)

  def max(c: Column[_]): DBFunction =
    max(c.s)

  def min(expr: SelectExpr): DBFunction =
    DBFunction.Min(expr)

  def min(c: Column[_]): DBFunction =
    min(c.s)

  def avg(expr: SelectExpr): DBFunction =
    DBFunction.Avg(expr)

  def sum(expr: SelectExpr): DBFunction =
    DBFunction.Sum(expr)

  def cast(expr: SelectExpr, targetType: String): DBFunction =
    DBFunction.Cast(expr, targetType)

  def castNumeric(expr: SelectExpr): DBFunction =
    DBFunction.CastNumeric(expr)

  def coalesce(expr: SelectExpr, more: SelectExpr*): DBFunction.Coalesce =
    DBFunction.Coalesce(expr, more.toVector)

  def power(base: Int, expr: SelectExpr): DBFunction =
    DBFunction.Power(expr, base)

  def substring(expr: SelectExpr, start: Int, length: Int): DBFunction =
    DBFunction.Substring(expr, start, length)

  def concat(expr: SelectExpr, exprs: SelectExpr*): DBFunction =
    DBFunction.Concat(Nel.of(expr, exprs: _*))

  def rawFunction(name: String, expr: SelectExpr, more: SelectExpr*): DBFunction =
    DBFunction.Raw(name, Nel.of(expr, more: _*))

  def const[A](value: A)(implicit P: Put[A]): SelectExpr.SelectConstant[A] =
    SelectExpr.SelectConstant(value, None)

  def lit(value: String): SelectExpr.SelectLiteral =
    SelectExpr.SelectLiteral(value, None)

  def plus(left: SelectExpr, right: SelectExpr): DBFunction =
    DBFunction.Calc(DBFunction.Operator.Plus, left, right)

  def mult(left: SelectExpr, right: SelectExpr): DBFunction =
    DBFunction.Calc(DBFunction.Operator.Mult, left, right)

  def and(c: Condition, cs: Condition*): Condition =
    c match {
      case a: Condition.And =>
        cs.foldLeft(a)(_.append(_))
      case _ =>
        Condition.And(c, cs: _*)
    }

  def or(c: Condition, cs: Condition*): Condition =
    c match {
      case o: Condition.Or =>
        cs.foldLeft(o)(_.append(_))
      case _ =>
        Condition.Or(c, cs: _*)
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

  implicit final class StringColumnOps(col: Column[String]) {
    def lowerEq(value: String): Condition =
      Condition.CompareVal(col, Operator.LowerEq, value.toLowerCase)

    def like(value: String): Condition =
      Condition.CompareVal(col, Operator.LowerLike, value.toLowerCase)

  }

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

    def decrement(amount: Int): Setter[A] =
      Setter.Decrement(col, amount)

    def asc: OrderBy =
      OrderBy(SelectExpr.SelectColumn(col, None), OrderBy.OrderType.Asc)

    def desc: OrderBy =
      OrderBy(SelectExpr.SelectColumn(col, None), OrderBy.OrderType.Desc)

    def ===(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.Eq, value)

    def lowerEqA(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.LowerEq, value)

    def ====(value: String): Condition =
      Condition.CompareVal(col.cast[String], Operator.Eq, value)

    def likeA(value: A)(implicit P: Put[A]): Condition =
      Condition.CompareVal(col, Operator.LowerLike, value)

    def likes(value: String): Condition =
      Condition.CompareVal(col.cast[String], Operator.LowerLike, value)

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

    def >(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Gt, subsel)
    def <(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Lt, subsel)
    def >=(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Gte, subsel)
    def <=(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Lte, subsel)
    def ===(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Eq, subsel)
    def !==(subsel: Select): Condition =
      Condition.CompareSelect(col.s, Operator.Neq, subsel)

    def notIn(subsel: Select): Condition =
      in(subsel).negate

    def in(values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col.s, values, lower = false)

    def notIn(values: Nel[A])(implicit P: Put[A]): Condition =
      in(values).negate

    def inLower(values: Nel[String]): Condition =
      Condition.InValues(col.s, values.map(_.toLowerCase), lower = true)

    def inLowerA(values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col.s, values, lower = true)

    def notInLower(values: Nel[String]): Condition =
      Condition.InValues(col.s, values.map(_.toLowerCase), lower = true).negate

    def notInLowerA(values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(col.s, values, lower = true).negate

    def isNull: Condition =
      Condition.IsNull(col.s)

    def isNotNull: Condition =
      Condition.IsNull(col.s).negate

    def ===(other: Column[A]): Condition =
      Condition.CompareCol(col, Operator.Eq, other)

    def <>(other: Column[A]): Condition =
      Condition.CompareCol(col, Operator.Neq, other)
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

    def as(otherCol: Column[_]): SelectExpr =
      SelectExpr.SelectFun(dbf, Some(otherCol.name))

    def asc: OrderBy =
      OrderBy(SelectExpr.SelectFun(dbf, None), OrderBy.OrderType.Asc)

    def desc: OrderBy =
      OrderBy(SelectExpr.SelectFun(dbf, None), OrderBy.OrderType.Desc)

    def ===[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Eq, value)

    def ====(value: String): Condition =
      Condition.CompareFVal(dbf.s, Operator.Eq, value)

    def like[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.LowerLike, value)

    def likes(value: String): Condition =
      Condition.CompareFVal(dbf.s, Operator.LowerLike, value)

    def <=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Lte, value)

    def >=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Gte, value)

    def >[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Gt, value)

    def <[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Lt, value)

    def <>[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(dbf.s, Operator.Neq, value)

    def -[A](value: A)(implicit P: Put[A]): DBFunction =
      DBFunction.Calc(
        DBFunction.Operator.Minus,
        SelectExpr.SelectFun(dbf, None),
        SelectExpr.SelectConstant(value, None)
      )
  }

  implicit final class SelectExprOps(sel: SelectExpr) {
    def isNull: Condition =
      Condition.IsNull(sel)

    def isNotNull: Condition =
      Condition.IsNull(sel).negate

    def ===[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Eq, value)

    def <=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Lte, value)

    def >=[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Gte, value)

    def >[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Gt, value)

    def <[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Lt, value)

    def <>[A](value: A)(implicit P: Put[A]): Condition =
      Condition.CompareFVal(sel, Operator.Neq, value)

    def in[A](values: Nel[A])(implicit P: Put[A]): Condition =
      Condition.InValues(sel, values, lower = false)
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
