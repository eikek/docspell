package docspell.store.qb

trait TableDef {
  def tableName: String

  def alias: Option[String]
}

object TableDef {

  def apply(table: String, aliasName: Option[String] = None): TableDef =
    new TableDef {
      def tableName: String     = table
      def alias: Option[String] = aliasName
    }
}
