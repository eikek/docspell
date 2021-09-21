/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import cats.data.{NonEmptyList => Nel}
import cats.parse.{Parser => P, Parser0}

object BasicParser {
  private[this] val whitespace: P[Unit] = P.charIn(" \t\r\n").void

  val ws0: Parser0[Unit] = whitespace.rep0.void
  val ws1: P[Unit]       = whitespace.rep.void

  val stringListSep: P[Unit] =
    (ws0.with1.soft ~ P.char(',') ~ ws0).void

  private[this] val basicString: P[String] =
    P.charsWhile(c =>
      c > ' ' && c != '"' && c != '\\' && c != ',' && c != '[' && c != ']' && c != '(' && c != ')'
    )

  private[this] val identChars: Set[Char] =
    (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "-_.").toSet

  val parenAnd: P[Unit] =
    P.stringIn(List("(&", "(and")).void <* ws0

  val parenClose: P[Unit] =
    ws0.soft.with1 *> P.char(')')

  val parenOr: P[Unit] =
    P.stringIn(List("(|", "(or")).void <* ws0

  val identParser: P[String] =
    P.charsWhile(identChars.contains)

  val singleString: P[String] =
    basicString.backtrack.orElse(StringUtil.quoted('"'))

  val stringOrMore: P[Nel[String]] =
    singleString.repSep(stringListSep)

  val bool: P[Boolean] = {
    val trueP  = P.stringIn(List("yes", "true", "Yes", "True")).as(true)
    val falseP = P.stringIn(List("no", "false", "No", "False")).as(false)
    trueP | falseP
  }

}
