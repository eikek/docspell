/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import java.time.{LocalDate, Period}

import docspell.query.ItemQuery._
import docspell.query.{Date, ItemQueryGen, ParseFailure}

import munit.{FunSuite, ScalaCheckSuite}
import org.scalacheck.Prop.forAll

class ExprStringTest extends FunSuite with ScalaCheckSuite {

  // parses the query without reducing and expanding macros
  def singleParse(s: String): Expr =
    ExprParser
      .parseQuery(s)
      .left
      .map(ParseFailure.fromError(s))
      .fold(f => sys.error(f.render), _.expr)

  def exprString(expr: Expr): String =
    ExprString(expr).fold(f => sys.error(f.toString), identity)

  test("macro: name") {
    val str = exprString(Expr.NamesMacro("test"))
    val q = singleParse(str)
    assertEquals(str, "names:\"test\"")
    assertEquals(q, Expr.NamesMacro("test"))
  }

  test("macro: year") {
    val str = exprString(Expr.YearMacro(Attr.Date, 1990))
    val q = singleParse(str)
    assertEquals(str, "year:1990")
    assertEquals(q, Expr.YearMacro(Attr.Date, 1990))
  }

  test("macro: daterange") {
    val range = Expr.DateRangeMacro(
      attr = Attr.Date,
      left = Date.Calc(
        date = Date.Local(
          date = LocalDate.of(2076, 12, 9)
        ),
        calc = Date.CalcDirection.Minus,
        period = Period.ofMonths(27)
      ),
      right = Date.Local(LocalDate.of(2076, 12, 9))
    )
    val str = exprString(range)
    val q = singleParse(str)
    assertEquals(str, "dateIn:2076-12-09;-27m")
    assertEquals(q, range)
  }

  property("generate expr and parse it") {
    forAll(ItemQueryGen.exprGen) { expr =>
      val str = exprString(expr)
      val q = singleParse(str)
      assertEquals(q, expr)
    }
  }
}
