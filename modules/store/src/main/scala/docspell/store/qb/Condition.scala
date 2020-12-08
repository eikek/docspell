package docspell.store.qb

import doobie._

sealed trait Condition {}

object Condition {

  case class CompareVal[A](column: Column[A], op: Operator, value: A)(implicit
      val P: Put[A]
  ) extends Condition

  case class CompareCol[A](col1: Column[A], op: Operator, col2: Column[A])
      extends Condition

  case class InSubSelect[A](col: Column[A], subSelect: Select) extends Condition

  case class And(c: Condition, cs: Vector[Condition]) extends Condition
  case class Or(c: Condition, cs: Vector[Condition])  extends Condition
  case class Not(c: Condition)                        extends Condition

}
