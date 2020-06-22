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
    offset: Int,
    highlight: FtsQuery.HighlightSetting
) {

  def nextPage: FtsQuery =
    copy(offset = limit + offset)
}

object FtsQuery {

  case class HighlightSetting(pre: String, post: String)

  object HighlightSetting {
    val default = HighlightSetting("**", "**")
  }
}
