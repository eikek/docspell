/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import docspell.jsonminiq.JsonMiniQuery.{Identity => JQ}

import munit._

class ParserTest extends FunSuite with Fixtures {

  test("field selects") {
    assertEquals(
      parse("content.added,removed.name"),
      JQ.at("content").at("added", "removed").at("name")
    )
  }

  test("array select") {
    assertEquals(parse("content(1,2).name"), JQ.at("content").at(1, 2).at("name"))
  }

  test("values") {
    assertEquals(parseP(Parser.value, "\"in voice\""), "in voice")
    assertEquals(parseP(Parser.value, "'in voice'"), "in voice")
    assertEquals(parseP(Parser.value, "invoice"), "invoice")
    intercept[Throwable](parseP(Parser.value, "in voice"))
  }

  test("anyMatch / allMatch") {
    assertEquals(parse("='invoice'"), JQ.isAll("invoice"))
    assertEquals(parse("=invoice"), JQ.isAll("invoice"))

    assertEquals(parse("name=invoice"), JQ.at("name").isAll("invoice"))
    assertEquals(parse("name=\"invoice\""), JQ.at("name").isAll("invoice"))
  }

  test("and / or") {
    assertEquals(
      parse("[c=d | e=f]"),
      (JQ.at("c") >> JQ.isAll("d")) || (JQ.at("e") >> JQ.isAll("f"))
    )

    assertEquals(
      parse("[a=1 | [b=2 & c=3]]"),
      (JQ.at("a") >> JQ.isAll("1")) || (
        (JQ.at("b") >> JQ.isAll("2")) && (JQ.at("c") >> JQ.isAll("3"))
      )
    )
  }
}
