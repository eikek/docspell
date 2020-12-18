package docspell.store.queries

import docspell.common._

/** Some preselected item from a fulltext search. */
case class SelectedItem(itemId: Ident, weight: Double)
