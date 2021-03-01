package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery._

object OperatorParser {
  private[this] val Eq: P[Operator] =
    P.char('=').as(Operator.Eq)

  private[this] val Neq: P[Operator] =
    P.string("!=").as(Operator.Neq)

  private[this] val Like: P[Operator] =
    P.char(':').as(Operator.Like)

  private[this] val Gt: P[Operator] =
    P.char('>').as(Operator.Gt)

  private[this] val Lt: P[Operator] =
    P.char('<').as(Operator.Lt)

  private[this] val Gte: P[Operator] =
    P.string(">=").as(Operator.Gte)

  private[this] val Lte: P[Operator] =
    P.string("<=").as(Operator.Lte)

  val op: P[Operator] =
    P.oneOf(List(Like, Eq, Neq, Gte, Lte, Gt, Lt))

  private[this] val anyOp: P[TagOperator] =
    P.char(':').as(TagOperator.AnyMatch)

  private[this] val allOp: P[TagOperator] =
    P.char('=').as(TagOperator.AllMatch)

  val tagOp: P[TagOperator] =
    P.oneOf(List(anyOp, allOp))
}
