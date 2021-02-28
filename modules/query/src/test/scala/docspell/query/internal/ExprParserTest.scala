package docspell.query.internal

import docspell.query.ItemQuery._
import munit._
import cats.data.{NonEmptyList => Nel}

class ExprParserTest extends FunSuite with ValueHelper {

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

  test("tag list inside and/or") {
    val p = ExprParser.exprParser
    assertEquals(
      p.parseAll("(& tag:a,b,c)"),
      Right(
        Expr.AndExpr(
          Nel.of(
            Expr.TagsMatch(TagOperator.AnyMatch, Nel.of("a", "b", "c"))
          )
        )
      )
    )
    assertEquals(
      p.parseAll("(& tag:a,b,c )"),
      Right(
        Expr.AndExpr(
          Nel.of(
            Expr.TagsMatch(TagOperator.AnyMatch, Nel.of("a", "b", "c"))
          )
        )
      )
    )
  }
}
