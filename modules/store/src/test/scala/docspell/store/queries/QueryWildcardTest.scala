/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import munit._

class QueryWildcardTest extends FunSuite {

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

  test("do not use multiple wildcards") {
    assertEquals("%", QueryWildcard("**"))
    assertEquals("%*%", QueryWildcard("***"))
  }
}
