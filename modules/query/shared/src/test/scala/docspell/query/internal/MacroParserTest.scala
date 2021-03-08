package docspell.query.internal

import munit._
//import cats.parse.{Parser => P}
import docspell.query.ItemQuery.Expr

class MacroParserTest extends FunSuite {

  test("recognize names shortcut") {
    val p = MacroParser.namesMacro
    assertEquals(p.parseAll("names:test"), Right(Expr.NamesMacro("test")))
    assert(p.parseAll("$names:test").isLeft)
  }

}
