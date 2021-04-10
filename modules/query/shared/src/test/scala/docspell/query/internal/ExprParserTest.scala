package docspell.query.internal

import cats.data.{NonEmptyList => Nel}

import docspell.query.ItemQuery._

import munit._

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

  test("nest and/ with simple expr") {
    val p = ExprParser.exprParser
    assertEquals(
      p.parseAll("(& (& f:usd=\"4.99\" ) source:*test* )"),
      Right(
        Expr.and(
          Expr.and(Expr.CustomFieldMatch("usd", Operator.Eq, "4.99")),
          Expr.string(Operator.Like, Attr.ItemSource, "*test*")
        )
      )
    )
    assertEquals(
      p.parseAll("(& (& f:usd=\"4.99\" ) (| source:*test*) )"),
      Right(
        Expr.and(
          Expr.and(Expr.CustomFieldMatch("usd", Operator.Eq, "4.99")),
          Expr.or(Expr.string(Operator.Like, Attr.ItemSource, "*test*"))
        )
      )
    )
  }
}
