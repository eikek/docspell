package docspell.store.queries

import minitest._

object QueryWildcardTest extends SimpleTestSuite {

  test("replace prefix") {
    assertEquals("%name", QueryWildcard("*name"))
    assertEquals("%some more", QueryWildcard("*some more"))
  }

  test("replace suffix") {
    assertEquals("name%", QueryWildcard("name*"))
    assertEquals("some other name%", QueryWildcard("some other name*"))
  }

  test("replace both sides") {
    assertEquals("%name%", QueryWildcard("*name*"))
    assertEquals("%some other name%", QueryWildcard("*some other name*"))
  }
}
