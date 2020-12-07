package docspell.store.qb

import docspell.store.qb.OrderBy.OrderType

final case class OrderBy(expr: SelectExpr, orderType: OrderType)

object OrderBy {

  sealed trait OrderType
  object OrderType {
    case object Asc  extends OrderType
    case object Desc extends OrderType
  }
}
