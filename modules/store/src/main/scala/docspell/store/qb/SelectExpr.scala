package docspell.store.qb

sealed trait SelectExpr

object SelectExpr {

  case class SelectColumn(column: Column[_]) extends SelectExpr

  case class SelectFun(fun: DBFunction) extends SelectExpr

}
