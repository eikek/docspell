package docspell.query

import cats.implicits._
import munit._
import docspell.query.FulltextExtract.Result

class FulltextExtractTest extends FunSuite {

  def findFts(q: String): Result = {
    val p = ItemQueryParser.parseUnsafe(q)
    FulltextExtract.findFulltext(p.expr)
  }

  def assertFts(qstr: String, expect: Result) =
    assertEquals(findFts(qstr), expect)

  def assertFtsSuccess(qstr: String, expect: Option[String]) = {
    val q = ItemQueryParser.parseUnsafe(qstr)
    assertEquals(findFts(qstr), Result.Success(q.expr, expect))
  }

  test("find fulltext as root") {
    assertEquals(findFts("content:what"), Result.Success(ItemQuery.all.expr, "what".some))
    assertEquals(
      findFts("content:\"what hello\""),
      Result.Success(ItemQuery.all.expr, "what hello".some)
    )
    assertEquals(
      findFts("content:\"what OR hello\""),
      Result.Success(ItemQuery.all.expr, "what OR hello".some)
    )
  }

  test("find no fulltext") {
    assertFtsSuccess("name:test", None)
  }

  test("find fulltext within and") {
    assertFtsSuccess("content:what name:test", "what".some)
    assertFtsSuccess("$names:marc* content:what name:test", "what".some)
    assertFtsSuccess(
      "$names:marc* date:2021-02 content:\"what else\" name:test",
      "what else".some
    )
  }

  test("too many fulltext searches") {
    assertFts("content:yes content:no", Result.TooMany)
    assertFts("content:yes (| name:test content:no)", Result.TooMany)
    assertFts("content:yes (| name:test (& date:2021-02 content:no))", Result.TooMany)
  }

  test("wrong fulltext search position") {
    assertFts("name:test (| date:2021-02 content:yes)", Result.UnsupportedPosition)
    assertFtsSuccess("name:test (& date:2021-02 content:yes)", "yes".some)
  }
}
