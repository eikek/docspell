/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.data.NonEmptyList
import fs2.io.file.Path

import docspell.analysis.TextAnalysisConfig
import docspell.analysis.classifier.TextClassifierConfig
import docspell.backend.Config.Files
import docspell.common._
import docspell.convert.ConvertConfig
import docspell.extract.ExtractConfig
import docspell.ftssolr.SolrConfig
import docspell.joex.analysis.RegexNerFile
import docspell.joex.hk.HouseKeepingConfig
import docspell.joex.routes.InternalHeader
import docspell.scheduler.{PeriodicSchedulerConfig, SchedulerConfig}
import docspell.joex.updatecheck.UpdateCheckConfig
import docspell.logging.LogConfig
import docspell.pubsub.naive.PubSubConfig
import docspell.store.JdbcConfig

case class Config(
    appId: Ident,
    baseUrl: LenientUri,
    logging: LogConfig,
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
    updateCheck: UpdateCheckConfig
) {

  def pubSubConfig(headerValue: Ident): PubSubConfig =
    PubSubConfig(
      appId,
      baseUrl / "internal" / "pubsub",
      100,
      InternalHeader.header(headerValue.id)
    )
}

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

  case class TextAnalysis(
      maxLength: Int,
      workingDir: Path,
      nlp: NlpConfig,
      classification: Classification
  ) {

    def textAnalysisConfig: TextAnalysisConfig =
      TextAnalysisConfig(
        maxLength,
        TextAnalysisConfig.NlpConfig(nlp.clearInterval, nlp.mode),
        TextClassifierConfig(
          workingDir,
          NonEmptyList
            .fromList(classification.classifiers)
            .getOrElse(NonEmptyList.of(Map.empty))
        )
      )

    def regexNerFileConfig: RegexNerFile.Config =
      RegexNerFile.Config(
        nlp.regexNer.maxEntries,
        workingDir,
        nlp.regexNer.fileCacheTime
      )
  }

  case class NlpConfig(
      mode: NlpMode,
      clearInterval: Duration,
      maxDueDateYears: Int,
      regexNer: RegexNer
  )

  case class RegexNer(maxEntries: Int, fileCacheTime: Duration)

  case class Classification(
      enabled: Boolean,
      itemCount: Int,
      classifiers: List[Map[String, String]]
  ) {

    def itemCountOrWhenLower(other: Int): Int =
      if (itemCount <= 0 || (itemCount > other && other > 0)) other
      else itemCount
  }
}
