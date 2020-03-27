package docspell.joex

import docspell.analysis.TextAnalysisConfig
import docspell.common.{Ident, LenientUri}
import docspell.joex.scheduler.{PeriodicSchedulerConfig, SchedulerConfig}
import docspell.store.JdbcConfig
import docspell.convert.ConvertConfig
import docspell.extract.ExtractConfig
import docspell.joex.hk.HouseKeepingConfig

case class Config(
    appId: Ident,
    baseUrl: LenientUri,
    bind: Config.Bind,
    jdbc: JdbcConfig,
    scheduler: SchedulerConfig,
    periodicScheduler: PeriodicSchedulerConfig,
    houseKeeping: HouseKeepingConfig,
    extraction: ExtractConfig,
    textAnalysis: TextAnalysisConfig,
    convert: ConvertConfig
)

object Config {
  case class Bind(address: String, port: Int)
}
