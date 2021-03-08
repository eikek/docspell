package docspell.query.internal

import cats.parse.Numbers
import cats.parse.{Parser => P}

import docspell.query.ItemQuery._

object SimpleExprParser {

  private[this] val op: P[Operator] =
    OperatorParser.op.surroundedBy(BasicParser.ws0)

  private[this] val inOp: P[Unit] =
    P.string("~=").surroundedBy(BasicParser.ws0)

  private[this] val inOrOpStr =
    P.eitherOr(op ~ BasicParser.singleString, inOp *> BasicParser.stringOrMore)

  private[this] val inOrOpDate =
    P.eitherOr(op ~ DateParser.date, inOp *> DateParser.dateOrMore)

  private[this] val opInt =
    op ~ Numbers.digits.map(_.toInt)

  val stringExpr: P[Expr] =
    (AttrParser.stringAttr ~ inOrOpStr).map {
      case (attr, Right((op, value))) =>
        Expr.SimpleExpr(op, Property.StringProperty(attr, value))
      case (attr, Left(values)) =>
        Expr.InExpr(attr, values)
    }

  val dateExpr: P[Expr] =
    (AttrParser.dateAttr ~ inOrOpDate).map {
      case (attr, Right((op, value))) =>
        Expr.SimpleExpr(op, Property.DateProperty(attr, value))
      case (attr, Left(values)) =>
        Expr.InDateExpr(attr, values)
    }

  val intExpr: P[Expr] =
    (AttrParser.intAttr ~ opInt).map { case (attr, (op, value)) =>
      Expr.SimpleExpr(op, Property(attr, value))
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
        Expr.CustomFieldMatch(name, op, value)
    }

  val customFieldIdExpr: P[Expr.CustomFieldIdMatch] =
    (P.string("f.id:") *> BasicParser.identParser ~ op ~ BasicParser.singleString).map {
      case ((name, op), value) =>
        Expr.CustomFieldIdMatch(name, op, value)
    }

  val inboxExpr: P[Expr.InboxExpr] =
    (P.string("inbox:") *> BasicParser.bool).map(Expr.InboxExpr.apply)

  val dirExpr: P[Expr.DirectionExpr] =
    (P.string("incoming:") *> BasicParser.bool).map(Expr.DirectionExpr.apply)

  val checksumExpr: P[Expr.ChecksumMatch] =
    (P.string("checksum:") *> BasicParser.singleString).map(Expr.ChecksumMatch.apply)

  val attachIdExpr: P[Expr.AttachId] =
    (P.ignoreCase("attach.id:") *> BasicParser.singleString).map(Expr.AttachId.apply)

  val simpleExpr: P[Expr] =
    P.oneOf(
      List(
        dateExpr,
        stringExpr,
        intExpr,
        existsExpr,
        fulltextExpr,
        tagIdExpr,
        tagExpr,
        catExpr,
        customFieldIdExpr,
        customFieldExpr,
        inboxExpr,
        dirExpr,
        checksumExpr,
        attachIdExpr
      )
    )
}
