/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.query.internal

import java.time.Period

import docspell.query.Date

import munit._

class DateParserTest extends FunSuite with ValueHelper {

  test("local date string") {
    val p = DateParser.dateFromString
    assertEquals(p.parseAll("2021-02-22"), Right(ld(2021, 2, 22)))
    assertEquals(p.parseAll("1999-11-11"), Right(ld(1999, 11, 11)))
    assertEquals(p.parseAll("2032-01-21"), Right(ld(2032, 1, 21)))
    assert(p.parseAll("0-0-0").isLeft)
    assert(p.parseAll("2021-02-30").isLeft)
  }

  test("local date millis") {
    val p = DateParser.dateFromMillis
    assertEquals(p.parseAll("ms0"), Right(Date(0)))
    assertEquals(
      p.parseAll("ms1600000065463"),
      Right(Date(1600000065463L))
    )
  }

  test("local date") {
    val p = DateParser.date
    assertEquals(p.parseAll("2021-02-22"), Right(ld(2021, 2, 22)))
    assertEquals(p.parseAll("1999-11-11"), Right(ld(1999, 11, 11)))
    assertEquals(p.parseAll("ms0"), Right(Date(0)))
    assertEquals(p.parseAll("ms1600000065463"), Right(Date(1600000065463L)))
  }

  test("local partial date") {
    val p = DateParser.date
    assertEquals(p.parseAll("2021-04"), Right(ld(2021, 4, 1)))
    assertEquals(p.parseAll("2021-12"), Right(ld(2021, 12, 1)))
    assert(p.parseAll("2021-13").isLeft)
    assert(p.parseAll("2021-28").isLeft)
    assertEquals(p.parseAll("2021"), Right(ld(2021, 1, 1)))
  }

  test("date calcs") {
    val p = DateParser.date
    assertEquals(p.parseAll("2020-02;+2d"), Right(ldPlus(2020, 2, 1, Period.ofDays(2))))
    assertEquals(
      p.parseAll("today;-2m"),
      Right(Date.Calc(Date.Today, Date.CalcDirection.Minus, Period.ofMonths(2)))
    )
  }

  test("period") {
    val p = DateParser.periods
    assertEquals(p.parseAll("15d"), Right(Period.ofDays(15)))
    assertEquals(p.parseAll("15m"), Right(Period.ofMonths(15)))
    assertEquals(p.parseAll("15d10m"), Right(Period.ofMonths(10).plus(Period.ofDays(15))))
    assertEquals(p.parseAll("10m15d"), Right(Period.ofMonths(10).plus(Period.ofDays(15))))
  }
}
