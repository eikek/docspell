package docspell.store.qb

import doobie._

sealed trait Setter[A]

object Setter {

  case class SetOptValue[A](column: Column[A], value: Option[A])(implicit val P: Put[A])
      extends Setter[Option[A]]

  case class SetValue[A](column: Column[A], value: A)(implicit val P: Put[A])
      extends Setter[A]

  case class Increment[A](column: Column[A], amount: Int) extends Setter[A]
  case class Decrement[A](column: Column[A], amount: Int) extends Setter[A]

}
