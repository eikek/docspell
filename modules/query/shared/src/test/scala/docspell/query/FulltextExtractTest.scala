/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query

import docspell.query.FulltextExtract.Result

import munit._

class FulltextExtractTest extends FunSuite {

  def findFts(q: String): Result = {
    val p = ItemQueryParser.parseUnsafe(q)
    FulltextExtract.findFulltext(p.expr)
  }

  def assertFts(qstr: String, expect: Result) =
    assertEquals(findFts(qstr), expect)

  def assertFtsSuccess(qstr: String, expect: String) = {
    val q = ItemQueryParser.parseUnsafe(qstr)
    assertEquals(findFts(qstr), Result.SuccessBoth(q.expr, expect))
  }

  def assertNoFts(qstr: String) = {
    val q = ItemQueryParser.parseUnsafe(qstr)
    assertEquals(findFts(qstr), Result.SuccessNoFulltext(q.expr))
  }

  test("find fulltext as root") {
    assertEquals(findFts("content:what"), Result.SuccessNoExpr("what"))
    assertEquals(
      findFts("content:\"what hello\""),
      Result.SuccessNoExpr("what hello")
    )
    assertEquals(
      findFts("content:\"what OR hello\""),
      Result.SuccessNoExpr("what OR hello")
    )

    assertEquals(
      findFts("(& content:\"what OR hello\" )"),
      Result.SuccessNoExpr("what OR hello")
    )
  }

  test("find no fulltext") {
    assertNoFts("name:test")
  }

  test("find fulltext within and") {
    assertFtsSuccess("content:what name:test", "what")
    assertFtsSuccess("names:marc* content:what name:test", "what")
    assertFtsSuccess(
      "names:marc* date:2021-02 content:\"what else\" name:test",
      "what else"
    )
  }

  test("too many fulltext searches") {
    assertFts("content:yes content:no", Result.TooMany)
    assertFts("content:yes (| name:test content:no)", Result.TooMany)
    assertFts("content:yes (| name:test (& date:2021-02 content:no))", Result.TooMany)
  }

  test("wrong fulltext search position") {
    assertFts("name:test (| date:2021-02 content:yes)", Result.UnsupportedPosition)
    assertFtsSuccess("name:test (& date:2021-02 content:yes)", "yes")
  }
}
