package docspell.query.internal

import cats.parse.{Parser => P}
import docspell.query.ItemQuery.Expr.CustomFieldMatch
import docspell.query.ItemQuery._

object SimpleExprParser {

  private[this] val op: P[Operator] =
    OperatorParser.op.surroundedBy(BasicParser.ws0)

  val stringExpr: P[Expr.SimpleExpr] =
    (AttrParser.stringAttr ~ op ~ BasicParser.singleString).map {
      case ((attr, op), value) =>
        Expr.SimpleExpr(op, Property.StringProperty(attr, value))
    }

  val dateExpr: P[Expr.SimpleExpr] =
    (AttrParser.dateAttr ~ op ~ DateParser.localDate).map { case ((attr, op), value) =>
      Expr.SimpleExpr(op, Property.DateProperty(attr, value))
    }

  val existsExpr: P[Expr.Exists] =
    (P.ignoreCase("exists:") *> AttrParser.anyAttr).map(attr => Expr.Exists(attr))

  val fulltextExpr: P[Expr.Fulltext] =
    (P.ignoreCase("content:") *> BasicParser.singleString).map(q => Expr.Fulltext(q))

  val tagIdExpr: P[Expr.TagIdsMatch] =
    (P.ignoreCase("tag.id") *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagIdsMatch(op, values)
    }

  val tagExpr: P[Expr.TagsMatch] =
    (P.ignoreCase("tag") *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagsMatch(op, values)
    }

  val catExpr: P[Expr.TagCategoryMatch] =
    (P.ignoreCase("cat") *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagCategoryMatch(op, values)
    }

  val customFieldExpr: P[Expr.CustomFieldMatch] =
    (P.string("f:") *> BasicParser.identParser ~ op ~ BasicParser.singleString).map {
      case ((name, op), value) =>
        CustomFieldMatch(name, op, value)
    }

  val simpleExpr: P[Expr] =
    P.oneOf(
      List(
        dateExpr,
        stringExpr,
        existsExpr,
        fulltextExpr,
        tagIdExpr,
        tagExpr,
        catExpr,
        customFieldExpr
      )
    )
}
