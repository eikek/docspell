package docspell.store.qb

case class Column[A](name: String, table: TableDef) {
  def inTable(t: TableDef): Column[A] =
    copy(table = t)

  def s: SelectExpr =
    SelectExpr.SelectColumn(this, None)

  def as(alias: String): SelectExpr =
    SelectExpr.SelectColumn(this, Some(alias))
}

object Column {}
