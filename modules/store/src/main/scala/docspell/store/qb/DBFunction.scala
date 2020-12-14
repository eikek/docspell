package docspell.store.qb

sealed trait DBFunction {}

object DBFunction {

  val countAll: DBFunction = CountAll

  def countAs[A](column: Column[A]): DBFunction =
    Count(column)

  case object CountAll extends DBFunction

  case class Count(column: Column[_]) extends DBFunction

  case class Max(column: Column[_]) extends DBFunction

  case class Min(column: Column[_]) extends DBFunction

  case class Coalesce(expr: SelectExpr, exprs: Vector[SelectExpr]) extends DBFunction

  case class Power(expr: SelectExpr, base: Int) extends DBFunction

  case class Calc(op: Operator, left: SelectExpr, right: SelectExpr) extends DBFunction

  case class Substring(expr: SelectExpr, start: Int, length: Int) extends DBFunction

  sealed trait Operator
  object Operator {
    case object Plus  extends Operator
    case object Minus extends Operator
    case object Mult  extends Operator
  }
}
