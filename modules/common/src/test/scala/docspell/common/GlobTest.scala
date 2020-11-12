package docspell.common

import minitest._
import Glob._

object GlobTest extends SimpleTestSuite {

  test("literals") {
    assert(Glob.pattern(Pattern(Segment(Token.Literal("hello")))).matches("hello"))
    assert(!Glob.pattern(Pattern(Segment(Token.Literal("hello")))).matches("hello1"))
  }

  test("single wildcards 1") {
    val glob =
      Glob.pattern(
        Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t")))
      )

    assert(glob.matches("snapshot"))
    assert(!glob.matches("snapshots"))
  }

  test("single wildcards 2") {
    val glob =
      Glob.pattern(Pattern(Segment(Token.Literal("test."), Token.Until(""))))

    assert(glob.matches("test.txt"))
    assert(glob.matches("test.pdf"))
    assert(glob.matches("test.converted.pdf"))
    assert(!glob.matches("test1.txt"))
    assert(!glob.matches("atest.txt"))
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
    assert(Glob("a/b/*").matches("a/b/hello"))
    assert(!Glob("a/b/*").matches("/a/b/hello"))
    assert(Glob("/a/b/*").matches("/a/b/hello"))
    assert(!Glob("/a/b/*").matches("a/b/hello"))
    assert(!Glob("*/a/b/*").matches("a/b/hello"))
    assert(Glob("*/a/b/*").matches("test/a/b/hello"))
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
    assert(Glob("/test.*").matches("/test.pdf"))
    assert(!Glob("/test.*").matches("test.pdf"))
    assert(!Glob("test.*").matches("/test.pdf"))
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
    assert(Glob("*.pdf|*.txt").matches("test.pdf"))
    assert(Glob("*.pdf|*.txt").matches("test.txt"))
    assert(!Glob("*.pdf|*.txt").matches("test.xls"))
    assert(Glob("*.pdf | *.txt").matches("test.pdf"))
    assert(Glob("*.pdf | mail.html").matches("test.pdf"))
    assert(Glob("*.pdf | mail.html").matches("mail.html"))
    assert(!Glob("*.pdf | mail.html").matches("test.docx"))
  }
}
