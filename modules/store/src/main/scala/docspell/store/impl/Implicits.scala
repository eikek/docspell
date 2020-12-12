package docspell.store.impl

object Implicits extends DoobieMeta with DoobieSyntax {

  implicit final class LegacySyntax(col: docspell.store.qb.Column[_]) {
    def oldColumn: Column =
      Column(col.name)

    def column: Column =
      col.table.alias match {
        case Some(p) => oldColumn.prefix(p)
        case None    => oldColumn
      }
  }
}
