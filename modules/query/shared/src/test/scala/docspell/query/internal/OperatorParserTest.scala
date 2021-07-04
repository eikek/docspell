/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.query.internal

import docspell.query.ItemQuery.{Operator, TagOperator}
import docspell.query.internal.OperatorParser

import munit._

class OperatorParserTest extends FunSuite {
  test("operator values") {
    val p = OperatorParser.op
    assertEquals(p.parseAll("="), Right(Operator.Eq))
    assertEquals(p.parseAll("!="), Right(Operator.Neq))
    assertEquals(p.parseAll(":"), Right(Operator.Like))
    assertEquals(p.parseAll("<"), Right(Operator.Lt))
    assertEquals(p.parseAll(">"), Right(Operator.Gt))
    assertEquals(p.parseAll("<="), Right(Operator.Lte))
    assertEquals(p.parseAll(">="), Right(Operator.Gte))
  }

  test("tag operators") {
    val p = OperatorParser.tagOp
    assertEquals(p.parseAll(":"), Right(TagOperator.AnyMatch))
    assertEquals(p.parseAll("="), Right(TagOperator.AllMatch))
  }
}
