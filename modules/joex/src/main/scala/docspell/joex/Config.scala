package docspell.joex

import docspell.analysis.TextAnalysisConfig
import docspell.common._
import docspell.joex.scheduler.{PeriodicSchedulerConfig, SchedulerConfig}
import docspell.store.JdbcConfig
import docspell.convert.ConvertConfig
import docspell.extract.ExtractConfig
import docspell.joex.hk.HouseKeepingConfig
import docspell.backend.Config.Files
import docspell.ftssolr.SolrConfig

case class Config(
    appId: Ident,
    baseUrl: LenientUri,
    bind: Config.Bind,
    jdbc: JdbcConfig,
    scheduler: SchedulerConfig,
    periodicScheduler: PeriodicSchedulerConfig,
    userTasks: Config.UserTasks,
    houseKeeping: HouseKeepingConfig,
    extraction: ExtractConfig,
    textAnalysis: TextAnalysisConfig,
    convert: ConvertConfig,
    sendMail: MailSendConfig,
    files: Files,
    mailDebug: Boolean,
    fullTextSearch: Config.FullTextSearch,
    processing: Config.Processing
)

object Config {
  case class Bind(address: String, port: Int)

  case class ScanMailbox(maxFolders: Int, mailChunkSize: Int, maxMails: Int) {
    def mailBatchSize: Int =
      math.min(mailChunkSize, maxMails)
  }
  case class UserTasks(scanMailbox: ScanMailbox)

  case class FullTextSearch(
      enabled: Boolean,
      migration: FullTextSearch.Migration,
      solr: SolrConfig
  )

  object FullTextSearch {

    final case class Migration(indexAllChunk: Int)
  }

  case class Processing(maxDueDateYears: Int)
}
