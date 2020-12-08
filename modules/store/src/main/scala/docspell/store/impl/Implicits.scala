package docspell.store.impl

object Implicits extends DoobieMeta with DoobieSyntax {

  implicit final class LegacySyntax(col: docspell.store.qb.Column[_]) {
    def oldColumn: Column =
      Column(col.name)

    def column: Column = {
      val c = col.alias match {
        case Some(a) => oldColumn.as(a)
        case None    => oldColumn
      }
      col.table.alias match {
        case Some(p) => c.prefix(p)
        case None    => c
      }
    }
  }
}
