package docspell.store.qb

import cats.data.NonEmptyList

import doobie._

sealed trait Condition

object Condition {
  case object UnitCondition extends Condition

  val unit: Condition = UnitCondition

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

  case class And(inner: NonEmptyList[Condition]) extends Condition {
    def append(other: Condition): And =
      other match {
        case And(otherInner) =>
          And(inner.concatNel(otherInner))
        case _ =>
          And(inner.append(other))
      }
  }
  object And {
    def apply(c: Condition, cs: Condition*): And =
      And(NonEmptyList(c, cs.toList))

    object Inner extends InnerCondition {
      def unapply(node: Condition): Option[NonEmptyList[Condition]] =
        node match {
          case n: And =>
            Option(n.inner)
          case _ =>
            None
        }
    }
  }

  case class Or(inner: NonEmptyList[Condition]) extends Condition {
    def append(other: Condition): Or =
      other match {
        case Or(otherInner) =>
          Or(inner.concatNel(otherInner))
        case _ =>
          Or(inner.append(other))
      }
  }
  object Or {
    def apply(c: Condition, cs: Condition*): Or =
      Or(NonEmptyList(c, cs.toList))

    object Inner extends InnerCondition {
      def unapply(node: Condition): Option[NonEmptyList[Condition]] =
        node match {
          case n: Or =>
            Option(n.inner)
          case _ =>
            None
        }
    }
  }

  case class Not(c: Condition) extends Condition
  object Not {}

  trait InnerCondition {
    def unapply(node: Condition): Option[NonEmptyList[Condition]]
  }
}
