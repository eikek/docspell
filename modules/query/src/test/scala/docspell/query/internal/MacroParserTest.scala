package docspell.query.internal

import munit._
import cats.parse.{Parser => P}

class MacroParserTest extends FunSuite {

  test("fail with unkown macro names") {
    val p = MacroParser.parser(Map.empty)
    assert(p.parseAll("$bla:blup").isLeft) // TODO check error message
  }

  test("select correct parser") {
    val p =
      MacroParser.parser[Int](Map("one" -> P.anyChar.as(1), "two" -> P.anyChar.as(2)))
    assertEquals(p.parseAll("$one:y"), Right(1))
    assertEquals(p.parseAll("$two:y"), Right(2))
  }
}
