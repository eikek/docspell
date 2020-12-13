package docspell.store.qb

case class Column[A](name: String, table: TableDef) {
  def inTable(t: TableDef): Column[A] =
    copy(table = t)
}

object Column {}
