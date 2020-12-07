package docspell.store.qb

sealed trait Operator

object Operator {

  case object Eq        extends Operator
  case object Gt        extends Operator
  case object Lt        extends Operator
  case object Gte       extends Operator
  case object Lte       extends Operator
  case object LowerLike extends Operator

}
