package docspell.joex

import docspell.common.{Ident, LenientUri}
import docspell.joex.scheduler.SchedulerConfig
import docspell.store.JdbcConfig
import docspell.text.ocr.{Config => OcrConfig}

case class Config(appId: Ident
  , baseUrl: LenientUri
  , bind: Config.Bind
  , jdbc: JdbcConfig
  , scheduler: SchedulerConfig
  , extraction: OcrConfig
)

object Config {
  val postgres = JdbcConfig(LenientUri.unsafe("jdbc:postgresql://localhost:5432/docspelldev"), "dev", "dev")
  val h2 = JdbcConfig(LenientUri.unsafe("jdbc:h2:./target/docspelldev.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"), "sa", "")

  case class Bind(address: String, port: Int)
}
