package docspell.common

import minitest._
import Glob._

object GlobTest extends SimpleTestSuite {

  test("literals") {
    assert(Glob(Pattern(Segment(Token.Literal("hello")))).matches("hello"))
    assert(!Glob(Pattern(Segment(Token.Literal("hello")))).matches("hello1"))
  }

  test("single wildcards 1") {
    val glob =
      Glob(Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t"))))

    assert(glob.matches("snapshot"))
    assert(!glob.matches("snapshots"))
  }

  test("single wildcards 2") {
    val glob =
      Glob(Pattern(Segment(Token.Literal("test."), Token.Until(""))))

    assert(glob.matches("test.txt"))
    assert(glob.matches("test.pdf"))
    assert(glob.matches("test.converted.pdf"))
    assert(!glob.matches("test1.txt"))
    assert(!glob.matches("atest.txt"))
  }

  test("single parsing") {
    assertEquals(
      Glob("s*p*t"),
      Glob(Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t"))))
    )
    assertEquals(
      Glob("s***p*t"),
      Glob(Pattern(Segment(Token.Literal("s"), Token.Until("p"), Token.Until("t"))))
    )
    assertEquals(
      Glob("test.*"),
      Glob(Pattern(Segment(Token.Literal("test."), Token.Until(""))))
    )
    assertEquals(
      Glob("stop"),
      Glob(Pattern(Segment(Token.Literal("stop"))))
    )
    assertEquals(
      Glob("*stop"),
      Glob(Pattern(Segment(Token.Until("stop"))))
    )
    assertEquals(
      Glob("*"),
      Glob(Pattern(Segment(Token.Until(""))))
    )
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
  }
}
