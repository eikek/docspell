package docspell.store.queries

import docspell.common._

case class FolderCount(id: Ident, name: String, owner: IdRef, count: Int)
