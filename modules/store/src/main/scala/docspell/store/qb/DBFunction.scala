/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

import cats.data.NonEmptyList

sealed trait DBFunction {}

object DBFunction {

  val countAll: DBFunction = CountAll

  def countAs[A](column: Column[A]): DBFunction =
    Count(column, distinct = false)

  case object CountAll extends DBFunction

  case class Count(column: Column[_], distinct: Boolean) extends DBFunction

  case class Max(expr: SelectExpr) extends DBFunction

  case class Min(expr: SelectExpr) extends DBFunction

  case class Coalesce(expr: SelectExpr, exprs: Vector[SelectExpr]) extends DBFunction

  case class Power(expr: SelectExpr, base: Int) extends DBFunction

  case class Calc(op: Operator, left: SelectExpr, right: SelectExpr) extends DBFunction

  case class Substring(expr: SelectExpr, start: Int, length: Int) extends DBFunction

  case class Cast(expr: SelectExpr, newType: String) extends DBFunction

  case class CastNumeric(expr: SelectExpr) extends DBFunction

  case class Avg(expr: SelectExpr) extends DBFunction

  case class Sum(expr: SelectExpr) extends DBFunction

  case class Concat(exprs: NonEmptyList[SelectExpr]) extends DBFunction

  case class Raw(name: String, exprs: NonEmptyList[SelectExpr]) extends DBFunction

  sealed trait Operator
  object Operator {
    case object Plus extends Operator
    case object Minus extends Operator
    case object Mult extends Operator
  }
}
