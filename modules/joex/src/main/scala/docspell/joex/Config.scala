package docspell.joex

import java.nio.file.Path

import cats.data.NonEmptyList

import docspell.analysis.TextAnalysisConfig
import docspell.analysis.classifier.TextClassifierConfig
import docspell.backend.Config.Files
import docspell.common._
import docspell.convert.ConvertConfig
import docspell.extract.ExtractConfig
import docspell.ftssolr.SolrConfig
import docspell.joex.analysis.RegexNerFile
import docspell.joex.hk.HouseKeepingConfig
import docspell.joex.scheduler.{PeriodicSchedulerConfig, SchedulerConfig}
import docspell.store.JdbcConfig

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
    textAnalysis: Config.TextAnalysis,
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

  case class TextAnalysis(
      maxLength: Int,
      workingDir: Path,
      nlpConfig: TextAnalysisConfig.NlpConfig,
      regexNer: RegexNer,
      classification: Classification
  ) {

    def textAnalysisConfig: TextAnalysisConfig =
      TextAnalysisConfig(
        maxLength,
        nlpConfig,
        TextClassifierConfig(
          workingDir,
          NonEmptyList
            .fromList(classification.classifiers)
            .getOrElse(NonEmptyList.of(Map.empty))
        )
      )

    def regexNerFileConfig: RegexNerFile.Config =
      RegexNerFile.Config(regexNer.enabled, workingDir, regexNer.fileCacheTime)
  }

  case class RegexNer(enabled: Boolean, fileCacheTime: Duration)

  case class Classification(
      enabled: Boolean,
      itemCount: Int,
      classifiers: List[Map[String, String]]
  )
}
