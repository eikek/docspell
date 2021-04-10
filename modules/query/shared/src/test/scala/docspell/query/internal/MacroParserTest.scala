package docspell.query.internal

import docspell.query.ItemQuery.Expr

import munit._

class MacroParserTest extends FunSuite {

  test("recognize names shortcut") {
    val p = MacroParser.namesMacro
    assertEquals(p.parseAll("names:test"), Right(Expr.NamesMacro("test")))
    assert(p.parseAll("$names:test").isLeft)
  }

}
