package docspell.backend.ops

import docspell.backend.ops.OItemSearch.ListItemWithTags
import docspell.common.ItemQueryString
import docspell.store.qb.Batch

trait OSimpleSearch[F[_]] {

  def searchByString(q: ItemQueryString, batch: Batch): F[Vector[ListItemWithTags]]

}

object OSimpleSearch {}
