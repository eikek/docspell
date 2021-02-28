package docspell.query.internal

import cats.data.{NonEmptyList => Nel}
import docspell.query.ItemQuery._
import munit._
import docspell.query.Date
import java.time.Period

class SimpleExprParserTest extends FunSuite with ValueHelper {

  test("string expr") {
    val p = SimpleExprParser.stringExpr
    assertEquals(
      p.parseAll("name:hello"),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello"))
    )
    assertEquals(
      p.parseAll("name:  hello"),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello"))
    )
    assertEquals(
      p.parseAll("name:\"hello world\""),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello world"))
    )
    assertEquals(
      p.parseAll("name : \"hello world\""),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello world"))
    )
    assertEquals(
      p.parseAll("conc.pers.id=Aaiet-aied"),
      Right(stringExpr(Operator.Eq, Attr.Concerning.PersonId, "Aaiet-aied"))
    )
    assert(p.parseAll("conc.pers.id=Aaiet,aied").isLeft)
    assertEquals(
      p.parseAll("name~=hello,world"),
      Right(Expr.InExpr(Attr.ItemName, Nel.of("hello", "world")))
    )
  }

  test("date expr") {
    val p = SimpleExprParser.dateExpr
    assertEquals(
      p.parseAll("date:2021-03-14"),
      Right(dateExpr(Operator.Like, Attr.Date, ld(2021, 3, 14)))
    )
    assertEquals(
      p.parseAll("due<2021-03-14"),
      Right(dateExpr(Operator.Lt, Attr.DueDate, ld(2021, 3, 14)))
    )
    assertEquals(
      p.parseAll("due~=2021-03-14,2021-03-13"),
      Right(Expr.InDateExpr(Attr.DueDate, Nel.of(ld(2021, 3, 14), ld(2021, 3, 13))))
    )
    assertEquals(
      p.parseAll("due>2021"),
      Right(dateExpr(Operator.Gt, Attr.DueDate, ld(2021, 1, 1)))
    )
    assertEquals(
      p.parseAll("date<2021-01"),
      Right(dateExpr(Operator.Lt, Attr.Date, ld(2021, 1, 1)))
    )
    assertEquals(
      p.parseAll("date<today"),
      Right(dateExpr(Operator.Lt, Attr.Date, Date.Today))
    )
    assertEquals(
      p.parseAll("date>today;-2m"),
      Right(
        dateExpr(
          Operator.Gt,
          Attr.Date,
          Date.Calc(Date.Today, Date.CalcDirection.Minus, Period.ofMonths(2))
        )
      )
    )
  }

  test("exists expr") {
    val p = SimpleExprParser.existsExpr
    assertEquals(p.parseAll("exists:name"), Right(Expr.Exists(Attr.ItemName)))
    assert(p.parseAll("exists:blabla").isLeft)
    assertEquals(
      p.parseAll("exists:conc.pers.id"),
      Right(Expr.Exists(Attr.Concerning.PersonId))
    )
  }

  test("fulltext expr") {
    val p = SimpleExprParser.fulltextExpr
    assertEquals(p.parseAll("content:test"), Right(Expr.Fulltext("test")))
    assertEquals(
      p.parseAll("content:\"hello world\""),
      Right(Expr.Fulltext("hello world"))
    )
  }

  test("category expr") {
    val p = SimpleExprParser.catExpr
    assertEquals(
      p.parseAll("cat:expense,doctype"),
      Right(Expr.TagCategoryMatch(TagOperator.AnyMatch, Nel.of("expense", "doctype")))
    )
  }

  test("custom field") {
    val p = SimpleExprParser.customFieldExpr
    assertEquals(
      p.parseAll("f:usd=26.66"),
      Right(Expr.CustomFieldMatch("usd", Operator.Eq, "26.66"))
    )
  }

  test("tag id expr") {
    val p = SimpleExprParser.tagIdExpr
    assertEquals(
      p.parseAll("tag.id:a,b,c"),
      Right(Expr.TagIdsMatch(TagOperator.AnyMatch, Nel.of("a", "b", "c")))
    )
    assertEquals(
      p.parseAll("tag.id:a"),
      Right(Expr.TagIdsMatch(TagOperator.AnyMatch, Nel.of("a")))
    )
    assertEquals(
      p.parseAll("tag.id=a,b,c"),
      Right(Expr.TagIdsMatch(TagOperator.AllMatch, Nel.of("a", "b", "c")))
    )
    assertEquals(
      p.parseAll("tag.id=a"),
      Right(Expr.TagIdsMatch(TagOperator.AllMatch, Nel.of("a")))
    )
    assertEquals(
      p.parseAll("tag.id=a,\"x y\""),
      Right(Expr.TagIdsMatch(TagOperator.AllMatch, Nel.of("a", "x y")))
    )
  }

  test("simple expr") {
    val p = SimpleExprParser.simpleExpr
    assertEquals(
      p.parseAll("name:hello"),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello"))
    )
    assertEquals(
      p.parseAll("name:hello"),
      Right(stringExpr(Operator.Like, Attr.ItemName, "hello"))
    )
    assertEquals(
      p.parseAll("due:2021-03-14"),
      Right(dateExpr(Operator.Like, Attr.DueDate, ld(2021, 3, 14)))
    )
    assertEquals(
      p.parseAll("due<2021-03-14"),
      Right(dateExpr(Operator.Lt, Attr.DueDate, ld(2021, 3, 14)))
    )
    assertEquals(
      p.parseAll("exists:conc.pers.id"),
      Right(Expr.Exists(Attr.Concerning.PersonId))
    )
    assertEquals(p.parseAll("content:test"), Right(Expr.Fulltext("test")))
    assertEquals(
      p.parseAll("tag.id:a"),
      Right(Expr.TagIdsMatch(TagOperator.AnyMatch, Nel.of("a")))
    )
    assertEquals(
      p.parseAll("tag.id=a,b,c"),
      Right(Expr.TagIdsMatch(TagOperator.AllMatch, Nel.of("a", "b", "c")))
    )
    assertEquals(
      p.parseAll("cat:expense,doctype"),
      Right(Expr.TagCategoryMatch(TagOperator.AnyMatch, Nel.of("expense", "doctype")))
    )
    assertEquals(
      p.parseAll("f:usd=26.66"),
      Right(Expr.CustomFieldMatch("usd", Operator.Eq, "26.66"))
    )
  }

}
