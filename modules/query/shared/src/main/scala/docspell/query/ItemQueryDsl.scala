/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query

import cats.data.NonEmptyList

import docspell.query.ItemQuery._
import docspell.query.internal.ExprUtil

object ItemQueryDsl {

  implicit final class StringAttrDsl(val attr: Attr.StringAttr) extends AnyVal {
    def ===(value: String): Expr =
      Expr.SimpleExpr(Operator.Eq, Property(attr, value))

    def <=(value: String): Expr =
      Expr.SimpleExpr(Operator.Lte, Property(attr, value))
    def >=(value: String): Expr =
      Expr.SimpleExpr(Operator.Gte, Property(attr, value))

    def <(value: String): Expr =
      Expr.SimpleExpr(Operator.Lt, Property(attr, value))
    def >(value: String): Expr =
      Expr.SimpleExpr(Operator.Gt, Property(attr, value))

    def in(values: NonEmptyList[String]): Expr =
      Expr.InExpr(attr, values)

    def exists: Expr =
      Expr.Exists(attr)

    def notExists: Expr =
      Expr.NotExpr(exists)
  }

  implicit final class DateAttrDsl(val attr: Attr.DateAttr) extends AnyVal {
    def <=(value: Date): Expr =
      Expr.SimpleExpr(Operator.Lte, Property(attr, value))

    def >=(value: Date): Expr =
      Expr.SimpleExpr(Operator.Gte, Property(attr, value))
  }

  implicit final class ExprDsl(val expr: Expr) extends AnyVal {
    def &&(other: Expr): Expr =
      ExprUtil.reduce(Expr.and(expr, other))

    def ||(other: Expr): Expr =
      ExprUtil.reduce(Expr.or(expr, other))

    def &&?(other: Option[Expr]): Expr =
      other.map(e => &&(e)).getOrElse(expr)

    def ||?(other: Option[Expr]): Expr =
      other.map(e => ||(e)).getOrElse(expr)

    def negate: Expr =
      ExprUtil.reduce(Expr.NotExpr(expr))

    def unary_! : Expr =
      negate
  }

  object Q {
    def tagIdsIn(values: NonEmptyList[String]): Expr =
      Expr.TagIdsMatch(TagOperator.AnyMatch, values)

    def tagIdsEq(values: NonEmptyList[String]): Expr =
      Expr.TagIdsMatch(TagOperator.AllMatch, values)

    def tagsIn(values: NonEmptyList[String]): Expr =
      Expr.TagsMatch(TagOperator.AnyMatch, values)

    def tagsEq(values: NonEmptyList[String]): Expr =
      Expr.TagsMatch(TagOperator.AllMatch, values)

  }
}
