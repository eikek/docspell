package docspell.ftsclient

import docspell.common._

/** A fulltext query.
  *
  * The query itself is a raw string. Each implementation may
  * interpret it according to the system in use.
  */
final case class FtsQuery(q: String, collective: Ident, limit: Int, offset: Int)
