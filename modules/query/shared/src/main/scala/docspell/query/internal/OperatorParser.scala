package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery._
import docspell.query.internal.{Constants => C}

object OperatorParser {
  private[this] val Eq: P[Operator] =
    P.char(C.eqs).as(Operator.Eq)

  private[this] val Neq: P[Operator] =
    P.string(C.neq).as(Operator.Neq)

  private[this] val Like: P[Operator] =
    P.char(C.like).as(Operator.Like)

  private[this] val Gt: P[Operator] =
    P.char(C.gt).as(Operator.Gt)

  private[this] val Lt: P[Operator] =
    P.char(C.lt).as(Operator.Lt)

  private[this] val Gte: P[Operator] =
    P.string(C.gte).as(Operator.Gte)

  private[this] val Lte: P[Operator] =
    P.string(C.lte).as(Operator.Lte)

  val op: P[Operator] =
    P.oneOf(List(Like, Eq, Neq, Gte, Lte, Gt, Lt))

  private[this] val anyOp: P[TagOperator] =
    P.char(C.like).as(TagOperator.AnyMatch)

  private[this] val allOp: P[TagOperator] =
    P.char(C.eqs).as(TagOperator.AllMatch)

  val tagOp: P[TagOperator] =
    P.oneOf(List(anyOp, allOp))
}
