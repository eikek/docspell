package docspell.query

import docspell.query.ItemQuery._
import docspell.query.SimpleExprParserTest.stringExpr
import docspell.query.internal.ExprParser
import minitest._
import cats.data.{NonEmptyList => Nel}

object ExprParserTest extends SimpleTestSuite {

  test("simple expr") {
    val p = ExprParser.exprParser
    assertEquals(
      p.parseAll("name:hello"),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello"))
    )
  }

  test("and") {
    val p = ExprParser.exprParser
    assertEquals(
      p.parseAll("(& name:hello source=webapp )"),
      Right(
        Expr.AndExpr(
          Nel.of(
            stringExpr(Operator.Like, Attr.ItemName, "hello"),
            stringExpr(Operator.Eq, Attr.ItemSource, "webapp")
          )
        )
      )
    )
  }

  test("or") {
    val p = ExprParser.exprParser
    assertEquals(
      p.parseAll("(| name:hello source=webapp )"),
      Right(
        Expr.OrExpr(
          Nel.of(
            stringExpr(Operator.Like, Attr.ItemName, "hello"),
            stringExpr(Operator.Eq, Attr.ItemSource, "webapp")
          )
        )
      )
    )
  }
}
