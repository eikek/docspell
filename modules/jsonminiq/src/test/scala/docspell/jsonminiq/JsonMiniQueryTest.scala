/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import docspell.jsonminiq.JsonMiniQuery.{Identity => JQ}

import io.circe.Encoder
import io.circe.Json
import io.circe.syntax._
import munit._

class JsonMiniQueryTest extends FunSuite with Fixtures {

  def values[T: Encoder](v1: T, vn: T*): Vector[Json] =
    (v1 +: vn.toVector).map(_.asJson)

  test("combine values on same level") {
    val q = JQ
      .at("content")
      .at("added", "removed")
      .at("name")

    assertEquals(q(sampleEvent), values("Invoice", "Grocery", "Receipt"))
  }

  test("combine values from different levels") {
    val q1 = JQ.at("account")
    val q2 = JQ.at("removed").at("name")
    val q = JQ.at("content") >> (q1 ++ q2)

    assertEquals(q(sampleEvent), values("demo", "Receipt"))
  }

  test("filter single value") {
    val q = JQ.at("account").at("login").isAll("demo")
    assertEquals(q(sampleEvent), values("demo"))

    val q2 = JQ.at("account").at("login").isAll("james")
    assertEquals(q2(sampleEvent), Vector.empty)
  }

  test("combine filters") {
    val q1 = JQ.at("account").at("login").isAll("demo")
    val q2 = JQ.at("eventType").isAll("tagschanged")
    val q3 = JQ.at("content").at("added", "removed").at("name").isAny("invoice")

    val q = q1 && q2 && q3
    assertEquals(
      q(sampleEvent),
      values("demo", "TagsChanged", "Invoice")
    )

    val q11 = JQ.at("account").at("login").isAll("not-exists")
    val r = q11 && q2 && q3
    assertEquals(r(sampleEvent), Vector.empty)
  }

  // content.[added,removed].(category=expense & name=grocery)
  test("combine fields and filter") {
    val andOk = JQ.at("content").at("added", "removed") >>
      (JQ.at("name").is("grocery") && JQ.at("category").is("expense"))
    assert(andOk.matches(sampleEvent))

    val andNotOk = JQ.at("content").at("added", "removed") >>
      (JQ.at("name").is("grocery") && JQ.at("category").is("notexist"))
    assert(andNotOk.notMatches(sampleEvent))

    val orOk = JQ.at("content").at("added", "removed") >>
      (JQ.at("name").is("grocery") || JQ.at("category").is("notexist"))
    assert(orOk.matches(sampleEvent))
  }

  test("thenAny combine via or") {
    val q = JQ
      .at("content")
      .thenAny(
        JQ.is("not this"),
        JQ.at("account"),
        JQ.at("oops")
      )
    assert(q.matches(sampleEvent))
  }

  test("thenAll combine via and (1)") {
    val q = JQ
      .at("content")
      .thenAll(
        JQ.is("not this"),
        JQ.at("account"),
        JQ.at("oops")
      )
    assert(q.notMatches(sampleEvent))
  }

  test("thenAll combine via and (2)") {
    val q = JQ
      .at("content")
      .thenAll(
        JQ.at("items").at("date").is("2021-10-06"),
        JQ.at("account"),
        JQ.at("added").at("name")
      )
    assert(q.matches(sampleEvent))

    // equivalent
    val q2 = JQ.at("content") >> (
      JQ.at("items").at("date").is("2021-10-06") &&
        JQ.at("account") &&
        JQ.at("added").at("name")
    )
    assert(q2.matches(sampleEvent))
  }

  test("test for null/not null") {
    val q1 = parse("content.items.notes=*null*")
    assert(q1.matches(sampleEvent))

    val q2 = parse("content.items.notes=bla")
    assert(q2.notMatches(sampleEvent))

    val q3 = parse("content.items.notes!*null*")
    assert(q3.notMatches(sampleEvent))
  }

  test("more real expressions") {
    val q = parse("content.added,removed[name=invoice | category=expense]")
    assert(q.matches(sampleEvent))
  }

  test("examples") {
    val q0 = parse("a.b.x,y")
    val json = parseJson(
      """[{"a": {"b": {"x": 1, "y":2}}, "v": 0}, {"a": {"b": {"y": 9, "b": 2}}, "z": 0}]"""
    )
    assertEquals(q0(json), values(1, 2, 9))

    val q1 = parse("a(0,2)")
    val json1 = parseJson("""[{"a": [10,9,8,7]}, {"a": [1,2,3,4]}]""")
    assertEquals(q1(json1), values(10, 8))

    val q2 = parse("=blue")
    val json2 = parseJson("""["blue", "green", "red"]""")
    assertEquals(q2(json2), values("blue"))

    val q3 = parse("color=blue")
    val json3 = parseJson(
      """[{"color": "blue", "count": 2}, {"color": "blue", "count": 1}, {"color": "blue", "count": 3}]"""
    )
    assertEquals(q3(json3), values("blue", "blue", "blue"))

    val q4 = parse("[count=6 | name=max]")
    val json4 = parseJson(
      """[{"name":"max", "count":4}, {"name":"me", "count": 3}, {"name":"max", "count": 3}]"""
    )
    println(q4(json4))
  }
}
