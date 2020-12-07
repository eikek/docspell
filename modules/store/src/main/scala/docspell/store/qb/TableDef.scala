package docspell.store.qb

trait TableDef {
  def tableName: String

  def alias: Option[String]
}
