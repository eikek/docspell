package docspell.query.internal

import cats.parse.Numbers
import cats.parse.{Parser => P}

import docspell.query.ItemQuery._
import docspell.query.internal.{Constants => C}

object SimpleExprParser {

  private[this] val op: P[Operator] =
    OperatorParser.op.surroundedBy(BasicParser.ws0)

  private[this] val inOp: P[Unit] =
    P.string(C.in).surroundedBy(BasicParser.ws0)

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
    (P.ignoreCase(C.exist) *> P.char(C.like) *> AttrParser.anyAttr).map(attr =>
      Expr.Exists(attr)
    )

  val fulltextExpr: P[Expr.Fulltext] =
    (P.ignoreCase(C.content) *> P.char(C.like) *> BasicParser.singleString).map(q =>
      Expr.Fulltext(q)
    )

  val tagIdExpr: P[Expr.TagIdsMatch] =
    (P.ignoreCase(C.tagId) *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagIdsMatch(op, values)
    }

  val tagExpr: P[Expr.TagsMatch] =
    (P.ignoreCase(C.tag) *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagsMatch(op, values)
    }

  val catExpr: P[Expr.TagCategoryMatch] =
    (P.ignoreCase(C.cat) *> OperatorParser.tagOp ~ BasicParser.stringOrMore).map {
      case (op, values) =>
        Expr.TagCategoryMatch(op, values)
    }

  val customFieldExpr: P[Expr.CustomFieldMatch] =
    (P.string(C.customField) *> P.char(
      C.like
    ) *> BasicParser.identParser ~ op ~ BasicParser.singleString)
      .map { case ((name, op), value) =>
        Expr.CustomFieldMatch(name, op, value)
      }

  val customFieldIdExpr: P[Expr.CustomFieldIdMatch] =
    (P.string(C.customFieldId) *> P.char(
      C.like
    ) *> BasicParser.identParser ~ op ~ BasicParser.singleString)
      .map { case ((name, op), value) =>
        Expr.CustomFieldIdMatch(name, op, value)
      }

  val inboxExpr: P[Expr.InboxExpr] =
    (P.string(C.inbox) *> P.char(C.like) *> BasicParser.bool).map(Expr.InboxExpr.apply)

  val dirExpr: P[Expr.DirectionExpr] =
    (P.string(C.incoming) *> P.char(C.like) *> BasicParser.bool)
      .map(Expr.DirectionExpr.apply)

  val checksumExpr: P[Expr.ChecksumMatch] =
    (P.string(C.checksum) *> P.char(C.like) *> BasicParser.singleString)
      .map(Expr.ChecksumMatch.apply)

  val attachIdExpr: P[Expr.AttachId] =
    (P.ignoreCase(C.attachId) *> P.char(C.eqs) *> BasicParser.singleString)
      .map(Expr.AttachId.apply)

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
