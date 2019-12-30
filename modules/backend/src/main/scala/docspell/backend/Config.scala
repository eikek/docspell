package docspell.backend

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.MimeType
import docspell.store.JdbcConfig

case class Config(jdbc: JdbcConfig, signup: SignupConfig, files: Config.Files) {}

object Config {

  case class Files(chunkSize: Int, validMimeTypes: Seq[MimeType])
}
