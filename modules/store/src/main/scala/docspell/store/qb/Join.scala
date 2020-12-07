package docspell.store.qb

sealed trait Join

object Join {

  case class InnerJoin(table: TableDef, cond: Condition) extends Join

  case class LeftJoin(table: TableDef, cond: Condition) extends Join
}
