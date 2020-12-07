package docspell.store.qb

case class Column[A](name: String, table: TableDef, alias: Option[String] = None)

object Column {}
