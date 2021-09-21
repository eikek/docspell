/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import cats.implicits._

import docspell.query.ItemQueryParser

import munit._

class ItemQueryParserTest extends FunSuite {

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

  test("throw if query is empty") {
    val result = ItemQueryParser.parse("")
    assert(result.isLeft)
  }

  test("splice inner and nodes") {
    val raw = "(& name:hello (& date:2021-02 name:world) (& name:hello) )"
    val q   = ItemQueryParser.parseUnsafe(raw)
    val expect =
      ItemQueryParser.parseUnsafe("name:hello date:2021-02 name:world name:hello")
    assertEquals(expect.copy(raw = raw.some), q)
  }

  test("splice inner or nodes") {
    val raw = "(| name:hello (| date:2021-02 name:world) (| name:hello) )"
    val q   = ItemQueryParser.parseUnsafe(raw)
    val expect =
      ItemQueryParser.parseUnsafe("(| name:hello date:2021-02 name:world name:hello )")
    assertEquals(expect.copy(raw = raw.some), q)
  }
}
