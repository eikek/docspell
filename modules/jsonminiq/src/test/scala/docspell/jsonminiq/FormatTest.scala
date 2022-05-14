/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import docspell.jsonminiq.JsonMiniQuery.{Identity => JQ}

import munit._

class FormatTest extends FunSuite with Fixtures {

  def format(q: JsonMiniQuery): String =
    q.unsafeAsString

  test("field selects") {
    assertEquals(
      format(JQ.at("content").at("added", "removed").at("name")),
      "content.added,removed.name"
    )
  }

  test("array select") {
    assertEquals(format(JQ.at("content").at(1, 2).at("name")), "content(1,2).name")
  }

  test("anyMatch / allMatch") {
    assertEquals(format(JQ.isAny("in voice")), ":'in voice'")
    assertEquals(format(JQ.isAll("invoice")), "=invoice")

    assertEquals(format(JQ.at("name").isAll("invoice")), "name=invoice")
    assertEquals(format(JQ.at("name").isAny("invoice")), "name:invoice")
  }

  test("and / or") {
    assertEquals(
      format(JQ.at("c") >> JQ.isAll("d") || JQ.at("e") >> JQ.isAll("f")),
      "[c=d | e=f]"
    )

    assertEquals(
      format(
        JQ.at("a").isAll("1") ||
          JQ.at("b").isAll("2") && JQ.at("c").isAll("3")
      ),
      "[a=1 | [b=2 & c=3]]"
    )
  }
}
