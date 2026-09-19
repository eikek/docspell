/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.addons.AddonTriggerType
import docspell.analysis.TextAnalyser
import docspell.backend.joex.AddonOps
import docspell.backend.ops.OItem
import docspell.common.ProcessItemArgs
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.scheduler.Task
import docspell.store.Store

object ProcessItem {
  type Args = ProcessItemArgs

  def apply[F[_]: Async: Files](
      cfg: Config,
      itemOps: OItem[F],
      fts: FtsClient[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      addonOps: AddonOps[F],
      store: Store[F]
  )(item: ItemData): Task[F, Args, ItemData] =
    isProcessingEnabled[F].flatMap {
      case true =>
        ExtractArchive(store)(item)
          .flatMap(Task.setProgress(20))
          .flatMap(processAttachments0(cfg, fts, analyser, regexNer, store, (40, 60, 80)))
          .flatMap(LinkProposal.onlyNew[F](store))
          .flatMap(SetGivenData.onlyNew[F](itemOps))
          .flatMap(Task.setProgress(99))
          .flatMap(RemoveEmptyItem(itemOps))
          .flatMap(RunAddons(addonOps, store, AddonTriggerType.FinalProcessItem))
      case false =>
        logStoreOnly[F]
          .flatMap(_ => SetGivenData.onlyNew[F](itemOps)(item))
          .flatMap(Task.setProgress(99))
    }

  def processAttachments[F[_]: Async: Files](
      cfg: Config,
      fts: FtsClient[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      store: Store[F]
  )(item: ItemData): Task[F, Args, ItemData] =
    processAttachments0[F](cfg, fts, analyser, regexNer, store, (30, 60, 90))(item)

  def analysisOnly[F[_]: Async: Files](
      cfg: Config,
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      store: Store[F]
  )(item: ItemData): Task[F, Args, ItemData] =
    TextAnalysis[F](cfg.textAnalysis, analyser, regexNer, store)(item)
      .flatMap(FindProposal[F](cfg.textAnalysis, store))
      .flatMap(EvalProposals[F](store))
      .flatMap(CrossCheckProposals[F](store))
      .flatMap(SaveProposals[F](store))

  private def processAttachments0[F[_]: Async: Files](
      cfg: Config,
      fts: FtsClient[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      store: Store[F],
      progress: (Int, Int, Int)
  )(item: ItemData): Task[F, Args, ItemData] =
    ConvertPdf(cfg.convert, store, item)
      .flatMap(Task.setProgress(progress._1))
      .flatMap(TextExtraction(cfg.extraction, fts, store))
      .flatMap(AttachmentPreview(cfg.extraction.preview, store))
      .flatMap(AttachmentPageCount(store))
      .flatMap(Task.setProgress(progress._2))
      .flatMap(analysisOnly[F](cfg, analyser, regexNer, store))
      .flatMap(Task.setProgress(progress._3))

  private def isProcessingEnabled[F[_]: Sync]: Task[F, Args, Boolean] =
    Task(ctx => ctx.args.isProcessingEnabled.pure[F])

  private def logStoreOnly[F[_]]: Task[F, Args, Unit] =
    Task.log(_.info("Not processing files. Only storing the item."))
}
