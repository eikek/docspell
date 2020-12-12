package docspell.store.qb

import cats.data.NonEmptyList

import doobie._

sealed trait Condition {
  def s: SelectExpr.SelectCondition =
    SelectExpr.SelectCondition(this, None)

  def as(alias: String): SelectExpr.SelectCondition =
    SelectExpr.SelectCondition(this, Some(alias))
}

object Condition {

  case class CompareVal[A](column: Column[A], op: Operator, value: A)(implicit
      val P: Put[A]
  ) extends Condition

  case class CompareFVal[A](dbf: DBFunction, op: Operator, value: A)(implicit
      val P: Put[A]
  ) extends Condition

  case class CompareCol[A](col1: Column[A], op: Operator, col2: Column[A])
      extends Condition

  case class InSubSelect[A](col: Column[A], subSelect: Select) extends Condition
  case class InValues[A](col: Column[A], values: NonEmptyList[A], lower: Boolean)(implicit
      val P: Put[A]
  ) extends Condition

  case class IsNull(col: Column[_]) extends Condition

  case class And(c: Condition, cs: Vector[Condition]) extends Condition
  case class Or(c: Condition, cs: Vector[Condition])  extends Condition
  case class Not(c: Condition)                        extends Condition

}
