package docspell.store.qb

case class Column[A](name: String, table: TableDef, alias: Option[String] = None) {
  def as(alias: String): Column[A] =
    copy(alias = Some(alias))
}

object Column {}
