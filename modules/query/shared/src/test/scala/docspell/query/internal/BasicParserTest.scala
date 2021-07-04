/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.query.internal

import cats.data.{NonEmptyList => Nel}

import docspell.query.internal.BasicParser

import munit._

class BasicParserTest extends FunSuite {
  test("single string values") {
    val p = BasicParser.singleString
    assertEquals(p.parseAll("abcde"), Right("abcde"))
    assert(p.parseAll("ab cd").isLeft)
    assertEquals(p.parseAll(""""ab cd""""), Right("ab cd"))
    assertEquals(p.parseAll(""""and \"this\" is""""), Right("""and "this" is"""))
  }

  test("string list values") {
    val p = BasicParser.stringOrMore
    assertEquals(p.parseAll("ab,cd,123"), Right(Nel.of("ab", "cd", "123")))
    assertEquals(p.parseAll("a,b"), Right(Nel.of("a", "b")))
    assert(p.parseAll("[a,b").isLeft)
  }

  test("stringvalue") {
    val p = BasicParser.stringOrMore
    assertEquals(p.parseAll("abcde"), Right(Nel.of("abcde")))
    assertEquals(p.parseAll(""""a,b,c""""), Right(Nel.of("a,b,c")))

    assertEquals(p.parse("a, b, c "), Right((" ", Nel.of("a", "b", "c"))))
  }
}
