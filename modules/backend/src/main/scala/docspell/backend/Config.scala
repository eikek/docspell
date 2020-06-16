package docspell.backend

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common._
import docspell.store.JdbcConfig
import docspell.ftssolr.SolrConfig

case class Config(
    mailDebug: Boolean,
    jdbc: JdbcConfig,
    signup: SignupConfig,
    files: Config.Files,
    fullTextSearch: Config.FullTextSearch
) {}

object Config {

  case class Files(chunkSize: Int, validMimeTypes: Seq[MimeType])

  case class FullTextSearch(enabled: Boolean, solr: SolrConfig)
}
