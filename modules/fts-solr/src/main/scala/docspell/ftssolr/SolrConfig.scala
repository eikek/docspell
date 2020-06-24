package docspell.ftssolr

import docspell.common._

final case class SolrConfig(url: LenientUri, commitWithin: Int, logVerbose: Boolean)

object SolrConfig {}
