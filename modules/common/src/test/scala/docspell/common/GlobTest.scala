/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import docspell.common.Glob._

import munit._

class GlobTest extends FunSuite {

  test("literals") {
    assert(Glob.pattern(Pattern(Segment(Token.Literal("hello")))).matches(true)("hello"))
    assert(
      !Glob.pattern(Pattern(Segment(Token.Literal("hello")))).matches(true)("hello1")
    )
  }

  test("single wildcards 1") {
    val glob =
      Glob.pattern(
        Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t")))
      )

    assert(glob.matches(true)("snapshot"))
    assert(!glob.matches(true)("snapshots"))
  }

  test("single wildcards 2") {
    val glob =
      Glob.pattern(Pattern(Segment(Token.Literal("test."), Token.Until(""))))

    assert(glob.matches(true)("test.txt"))
    assert(glob.matches(true)("test.pdf"))
    assert(glob.matches(true)("test.converted.pdf"))
    assert(!glob.matches(true)("test1.txt"))
    assert(!glob.matches(true)("atest.txt"))
  }

  test("single parsing") {
    assertEquals(
      Glob("s*p*t"),
      Glob.pattern(
        Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t")))
      )
    )
    assertEquals(
      Glob("s***p*t"),
      Glob.pattern(
        Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t")))
      )
    )
    assertEquals(
      Glob("test.*"),
      Glob.pattern(Pattern(Segment(Token.Literal("test."), Token.Until(""))))
    )
    assertEquals(
      Glob("stop"),
      Glob.pattern(Pattern(Segment(Token.Literal("stop"))))
    )
    assertEquals(
      Glob("*stop"),
      Glob.pattern(Pattern(Segment(Token.Until("stop"))))
    )
    assertEquals(Glob("*"), Glob.all)
  }

  test("with splitting") {
    assert(Glob("a/b/*").matches(true)("a/b/hello"))
    assert(!Glob("a/b/*").matches(true)("/a/b/hello"))
    assert(Glob("/a/b/*").matches(true)("/a/b/hello"))
    assert(!Glob("/a/b/*").matches(true)("a/b/hello"))
    assert(!Glob("*/a/b/*").matches(true)("a/b/hello"))
    assert(Glob("*/a/b/*").matches(true)("test/a/b/hello"))
  }

  test("asString") {
    assertEquals(Glob("test.*").asString, "test.*")
    assertEquals(Glob("s***p*t").asString, "s*p*t")
    assertEquals(Glob("stop").asString, "stop")
    assertEquals(Glob("*stop").asString, "*stop")
    assertEquals(Glob("/a/b/*").asString, "/a/b/*")
    assertEquals(Glob("*").asString, "*")
    assertEquals(Glob.all.asString, "*")
  }

  test("simple matches") {
    assert(Glob("/test.*").matches(true)("/test.pdf"))
    assert(!Glob("/test.*").matches(true)("test.pdf"))
    assert(!Glob("test.*").matches(true)("/test.pdf"))
  }

  test("matchFilenameOrPath") {
    assert(Glob("test.*").matchFilenameOrPath("/a/b/test.pdf"))
    assert(!Glob("/test.*").matchFilenameOrPath("/a/b/test.pdf"))
    assert(Glob("s*p*t").matchFilenameOrPath("snapshot"))
    assert(Glob("s*p*t").matchFilenameOrPath("/tmp/snapshot"))
    assert(Glob("/tmp/s*p*t").matchFilenameOrPath("/tmp/snapshot"))

    assert(Glob("a/b/*").matchFilenameOrPath("a/b/hello"))
    assert(!Glob("a/b/*").matchFilenameOrPath("/a/b/hello"))
    assert(Glob("/a/b/*").matchFilenameOrPath("/a/b/hello"))
    assert(!Glob("/a/b/*").matchFilenameOrPath("a/b/hello"))
    assert(!Glob("*/a/b/*").matchFilenameOrPath("a/b/hello"))
    assert(Glob("*/a/b/*").matchFilenameOrPath("test/a/b/hello"))
  }

  test("anyglob") {
    assert(Glob("*.pdf|*.txt").matches(true)("test.pdf"))
    assert(Glob("*.pdf|*.txt").matches(true)("test.txt"))
    assert(!Glob("*.pdf|*.txt").matches(true)("test.xls"))
    assert(Glob("*.pdf | *.txt").matches(true)("test.pdf"))
    assert(Glob("*.pdf | mail.html").matches(true)("test.pdf"))
    assert(Glob("*.pdf | mail.html").matches(true)("mail.html"))
    assert(!Glob("*.pdf | mail.html").matches(true)("test.docx"))
  }

  test("case insensitive") {
    assert(Glob("*hello*").matches(false)("hello world"))
    assert(Glob("*hello*").matches(false)("world hello"))
    assert(Glob("*hello*").matches(false)("Hello world"))
    assert(Glob("*hello*").matches(false)("world Hello"))
    assert(Glob("*hello*").matches(false)("World Hello"))
    assert(Glob("*hello*").matches(false)("Hello World"))
    assert(Glob("*Hello*").matches(false)("world hello"))
    assert(Glob("*heLLo*").matches(false)("Hello world"))
    assert(Glob("*hellO*").matches(false)("world Hello"))
  }
}
