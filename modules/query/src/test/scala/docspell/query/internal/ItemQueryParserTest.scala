package docspell.query.internal

import minitest._
import docspell.query.ItemQueryParser
import docspell.query.ItemQuery

object ItemQueryParserTest extends SimpleTestSuite {

  test("reduce ands") {
    val q    = ItemQueryParser.parseUnsafe("(&(&(&(& name:hello))))")
    val expr = ExprUtil.reduce(q.expr)
    assertEquals(expr, ItemQueryParser.parseUnsafe("name:hello").expr)
  }

  test("reduce ors") {
    val q    = ItemQueryParser.parseUnsafe("(|(|(|(| name:hello))))")
    val expr = ExprUtil.reduce(q.expr)
    assertEquals(expr, ItemQueryParser.parseUnsafe("name:hello").expr)
  }

  test("reduce and/or") {
    val q    = ItemQueryParser.parseUnsafe("(|(&(&(| name:hello))))")
    val expr = ExprUtil.reduce(q.expr)
    assertEquals(expr, ItemQueryParser.parseUnsafe("name:hello").expr)
  }

  test("reduce inner and/or") {
    val q    = ItemQueryParser.parseUnsafe("(& name:hello (| name:world))")
    val expr = ExprUtil.reduce(q.expr)
    assertEquals(expr, ItemQueryParser.parseUnsafe("(& name:hello name:world)").expr)
  }

  test("omit and-parens around root structure") {
    val q      = ItemQueryParser.parseUnsafe("name:hello date>2020-02-02")
    val expect = ItemQueryParser.parseUnsafe("(& name:hello date>2020-02-02 )")
    assertEquals(expect, q)
  }

  test("return all if query is empty") {
    val q = ItemQueryParser.parseUnsafe("")
    assertEquals(ItemQuery.all, q)
  }
}
