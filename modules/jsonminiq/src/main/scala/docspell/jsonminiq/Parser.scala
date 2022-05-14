/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import cats.data.NonEmptyVector
import cats.parse.{Parser => P, Parser0 => P0}

import docspell.jsonminiq.JsonMiniQuery.{Identity => JQ}

private[jsonminiq] object Parser {

  // a[,b]      -> at(string)
  // (1[,2,3])  -> at(int)
  // :b         -> isAny(b)
  // =b         -> isAll(b)
  // [F & G]    -> F && G
  // [F | G]    -> F || G

  private[this] val whitespace: P[Unit] = P.charIn(" \t\r\n").void
  private[this] val extraFieldChars = "_-".toSet
  private[this] val dontUse = "\"'\\[]()&|".toSet

  private[this] val ws0: P0[Unit] = whitespace.rep0.void

  private[this] val parenOpen: P[Unit] = P.char('(') *> ws0
  private[this] val parenClose: P[Unit] = ws0.with1 *> P.char(')')
  private[this] val bracketOpen: P[Unit] = P.char('[') *> ws0
  private[this] val bracketClose: P[Unit] = ws0.with1 *> P.char(']')
  private[this] val dot: P[Unit] = P.char('.')
  private[this] val comma: P[Unit] = P.char(',')
  private[this] val andSym: P[Unit] = ws0.with1 *> P.char('&') <* ws0
  private[this] val orSym: P[Unit] = ws0.with1 *> P.char('|') <* ws0
  private[this] val squote: P[Unit] = P.char('\'')
  private[this] val dquote: P[Unit] = P.char('"')
  private[this] val allOp: P[JsonMiniQuery.MatchType] =
    P.char('=').as(JsonMiniQuery.MatchType.All)
  private[this] val noneOp: P[JsonMiniQuery.MatchType] =
    P.char('!').as(JsonMiniQuery.MatchType.None)

  def isValidSimpleValue(c: Char): Boolean =
    c > ' ' && !dontUse.contains(c)

  val value: P[String] = {
    val simpleString: P[String] =
      P.charsWhile(isValidSimpleValue)

    val quotedString: P[String] = {
      val single: P[String] =
        squote *> P.charsWhile0(_ != '\'') <* squote

      val double: P[String] =
        dquote *> P.charsWhile0(_ != '"') <* dquote

      single | double
    }

    simpleString | quotedString
  }

  val field: P[String] =
    P.charsWhile(c => c.isLetterOrDigit || extraFieldChars.contains(c))
  val posNum: P[Int] = P.charsWhile(_.isDigit).map(_.toInt).filter(_ >= 0)

  val fieldSelect1: P[JsonMiniQuery] =
    field.repSep(comma).map(nel => JQ.at(nel.head, nel.tail: _*))

  val arraySelect1: P[JsonMiniQuery] = {
    val nums = posNum.repSep(1, comma)
    parenOpen.soft *> nums.map(f => JQ.at(f.head, f.tail: _*)) <* parenClose
  }

  val match1: P[JsonMiniQuery] =
    ((allOp | noneOp) ~ value).map { case (op, v) =>
      JsonMiniQuery.Filter(NonEmptyVector.of(v), op)
    }

  val segment = {
    val firstSegment = fieldSelect1 | arraySelect1 | match1
    val nextSegment = dot *> fieldSelect1 | arraySelect1 | match1

    (firstSegment ~ nextSegment.rep0).map { case (head, tail) =>
      tail.foldLeft(head)(_ >> _)
    }
  }

  def combine(inner: P[JsonMiniQuery]): P[JsonMiniQuery] = {
    val or = inner.repSep(orSym).map(_.reduceLeft(_ || _))
    val and = inner.repSep(andSym).map(_.reduceLeft(_ && _))

    and
      .between(bracketOpen, bracketClose)
      .backtrack
      .orElse(or.between(bracketOpen, bracketClose))
  }

  val query: P[JsonMiniQuery] =
    P.recursive[JsonMiniQuery] { recurse =>
      val comb = combine(recurse)
      P.oneOf(segment :: comb :: Nil).rep.map(_.reduceLeft(_ >> _))
    }
}
