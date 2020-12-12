package docspell.store.qb

trait TableDef {
  def tableName: String

  def alias: Option[String]
}

object TableDef {

  def apply(table: String, aliasName: Option[String] = None): TableDef =
    BasicTable(table, aliasName)

  final case class BasicTable(tableName: String, alias: Option[String]) extends TableDef {
    def as(alias: String): BasicTable =
      copy(alias = Some(alias))
  }

}
