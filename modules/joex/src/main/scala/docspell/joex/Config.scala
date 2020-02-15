package docspell.joex

import docspell.common.{Ident, LenientUri}
import docspell.joex.scheduler.SchedulerConfig
import docspell.store.JdbcConfig
import docspell.extract.ocr.{Config => OcrConfig}
import docspell.convert.ConvertConfig

case class Config(
    appId: Ident,
    baseUrl: LenientUri,
    bind: Config.Bind,
    jdbc: JdbcConfig,
    scheduler: SchedulerConfig,
    extraction: OcrConfig,
    convert: ConvertConfig
)

object Config {
  case class Bind(address: String, port: Int)
}
