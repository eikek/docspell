/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery
import docspell.query.ItemQuery._
import docspell.query.internal.{Constants => C}

object ExprParser {

  def and(inner: P[Expr]): P[Expr.AndExpr] =
    inner
      .repSep(BasicParser.ws1)
      .between(BasicParser.parenAnd, BasicParser.parenClose)
      .map(Expr.AndExpr.apply)

  def or(inner: P[Expr]): P[Expr.OrExpr] =
    inner
      .repSep(BasicParser.ws1)
      .between(BasicParser.parenOr, BasicParser.parenClose)
      .map(Expr.OrExpr.apply)

  def not(inner: P[Expr]): P[Expr] =
    (P.char(C.notPrefix) *> inner).map(_.negate)

  val exprParser: P[Expr] =
    P.recursive[Expr] { recurse =>
      val andP   = and(recurse)
      val orP    = or(recurse)
      val notP   = not(recurse)
      val macros = MacroParser.all
      P.oneOf(macros :: SimpleExprParser.simpleExpr :: andP :: orP :: notP :: Nil)
    }

  def parseQuery(input: String): Either[P.Error, ItemQuery] = {
    val p = BasicParser.ws0 *> exprParser <* (BasicParser.ws0 ~ P.end)
    p.parseAll(input).map(expr => ItemQuery(expr, Some(input)))
  }
}
