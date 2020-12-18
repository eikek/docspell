package docspell.store.qb

import docspell.store.qb.OrderBy.OrderType

final case class OrderBy(expr: SelectExpr, orderType: OrderType)

object OrderBy {

  def asc(e: SelectExpr): OrderBy =
    OrderBy(e, OrderType.Asc)

  def desc(e: SelectExpr): OrderBy =
    OrderBy(e, OrderType.Desc)

  sealed trait OrderType
  object OrderType {
    case object Asc  extends OrderType
    case object Desc extends OrderType
  }
}
