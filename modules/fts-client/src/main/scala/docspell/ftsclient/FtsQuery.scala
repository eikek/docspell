package docspell.ftsclient

import docspell.common._

/** A fulltext query.
  *
  * The query itself is a raw string. Each implementation may
  * interpret it according to the system in use.
  *
  * Searches must only look for given collective and in the given list
  * of item ids.
  */
final case class FtsQuery(
    q: String,
    collective: Ident,
    items: Set[Ident],
    limit: Int,
    offset: Int
) {

  def nextPage: FtsQuery =
    copy(offset = limit + offset)
}
