/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import cats.data.{NonEmptyList => Nel}

import docspell.query.ItemQuery.Expr._
import docspell.query.ItemQuery._

object ExprUtil {

  def reduce(expr: Expr): Expr =
    reduce(expandMacros = true)(expr)

  /** Does some basic transformation, like unfolding nested and trees containing one value
    * etc.
    */
  def reduce(expandMacros: Boolean)(expr: Expr): Expr =
    expr match {
      case AndExpr(inner) =>
        val nodes = spliceAnd(inner)
        if (nodes.tail.isEmpty) reduce(expandMacros)(nodes.head)
        else AndExpr(nodes.map(reduce(expandMacros)))

      case OrExpr(inner) =>
        val nodes = spliceOr(inner)
        if (nodes.tail.isEmpty) reduce(expandMacros)(nodes.head)
        else OrExpr(nodes.map(reduce(expandMacros)))

      case NotExpr(inner) =>
        inner match {
          case NotExpr(inner2) =>
            reduce(expandMacros)(inner2)
          case InboxExpr(flag) =>
            InboxExpr(!flag)
          case DirectionExpr(flag) =>
            DirectionExpr(!flag)
          case _ =>
            NotExpr(reduce(expandMacros)(inner))
        }

      case m: MacroExpr =>
        if (expandMacros) {
          reduce(expandMacros)(m.body)
        } else {
          m
        }

      case DirectionExpr(_) =>
        expr

      case InboxExpr(_) =>
        expr

      case InExpr(_, _) =>
        expr

      case InDateExpr(_, _) =>
        expr

      case TagsMatch(_, _) =>
        expr
      case TagIdsMatch(_, _) =>
        expr
      case Exists(_) =>
        expr
      case Fulltext(_) =>
        expr
      case SimpleExpr(_, _) =>
        expr
      case TagCategoryMatch(_, _) =>
        expr
      case CustomFieldMatch(_, _, _) =>
        expr
      case CustomFieldIdMatch(_, _, _) =>
        expr
      case ChecksumMatch(_) =>
        expr
      case AttachId(_) =>
        expr
      case ValidItemStates =>
        expr
      case Trashed =>
        expr
      case ValidItemsOrTrashed =>
        expr
    }

  private def spliceAnd(nodes: Nel[Expr]): Nel[Expr] =
    nodes.flatMap {
      case Expr.AndExpr(inner) =>
        spliceAnd(inner)
      case node =>
        Nel.of(node)
    }
  private def spliceOr(nodes: Nel[Expr]): Nel[Expr] =
    nodes.flatMap {
      case Expr.OrExpr(inner) =>
        spliceOr(inner)
      case node =>
        Nel.of(node)
    }
}
