/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query

import cats.data.NonEmptyList

import docspell.query.internal.{ExprParser, ExprString, ExprUtil}

object ItemQueryParser {

  val PrivateExprError = ExprString.PrivateExprError
  type PrivateExprError = ExprString.PrivateExprError

  def parse(input: String): Either[ParseFailure, ItemQuery] =
    parse0(input, expandMacros = true)

  def parseKeepMacros(input: String): Either[ParseFailure, ItemQuery] =
    parse0(input, expandMacros = false)

  private def parse0(
      input: String,
      expandMacros: Boolean
  ): Either[ParseFailure, ItemQuery] =
    if (input.isEmpty)
      Left(
        ParseFailure("", 0, NonEmptyList.of(ParseFailure.SimpleMessage(0, "No input.")))
      )
    else {
      val in = if (input.charAt(0) == '(') input else s"(& $input )"
      ExprParser
        .parseQuery(in)
        .left
        .map(ParseFailure.fromError(in))
        .map(q => q.copy(expr = ExprUtil.reduce(expandMacros)(q.expr)))
    }

  def parseUnsafe(input: String): ItemQuery =
    parse(input).fold(m => sys.error(m.render), identity)

  def asString(q: ItemQuery.Expr): Either[PrivateExprError, String] =
    ExprString(q)

  def unsafeAsString(q: ItemQuery.Expr): String =
    asString(q).fold(f => sys.error(s"Cannot expose private query part: $f"), identity)

}
