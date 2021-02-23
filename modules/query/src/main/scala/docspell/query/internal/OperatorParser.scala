package docspell.query.internal

import cats.parse.{Parser => P}
import docspell.query.ItemQuery._

object OperatorParser {
  private[this] val Eq: P[Operator] =
    P.char('=').void.map(_ => Operator.Eq)

  private[this] val Like: P[Operator] =
    P.char(':').void.map(_ => Operator.Like)

  private[this] val Gt: P[Operator] =
    P.char('>').void.map(_ => Operator.Gt)

  private[this] val Lt: P[Operator] =
    P.char('<').void.map(_ => Operator.Lt)

  private[this] val Gte: P[Operator] =
    P.string(">=").map(_ => Operator.Gte)

  private[this] val Lte: P[Operator] =
    P.string("<=").map(_ => Operator.Lte)

  val op: P[Operator] =
    P.oneOf(List(Like, Eq, Gte, Lte, Gt, Lt))

  private[this] val anyOp: P[TagOperator] =
    P.char(':').map(_ => TagOperator.AnyMatch)

  private[this] val allOp: P[TagOperator] =
    P.char('=').map(_ => TagOperator.AllMatch)

  val tagOp: P[TagOperator] =
    P.oneOf(List(anyOp, allOp))
}
