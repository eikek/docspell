/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.backend.ops.OItem
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachment
import docspell.store.records.RAttachmentSource
import docspell.store.records.RCollective
import docspell.store.records.RItem

object ReProcessItem {
  type Args = ReProcessItemArgs

  def apply[F[_]: Async](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F]
  ): Task[F, Args, Unit] =
    Task
      .log[F, Args](_.info("===== Start reprocessing ======"))
      .flatMap(_ =>
        loadItem[F]
          .flatMap(safeProcess[F](cfg, fts, itemOps, analyser, regexNer))
          .map(_ => ())
      )

  def onCancel[F[_]]: Task[F, Args, Unit] =
    logWarn("Now cancelling re-processing.")

  // --- Helpers

  private def contains[F[_]](ctx: Context[F, Args]): RAttachment => Boolean = {
    val selection = ctx.args.attachments.toSet
    if (selection.isEmpty) (_ => true)
    else ra => selection.contains(ra.id)
  }

  def loadItem[F[_]: Sync]: Task[F, Args, ItemData] =
    Task { ctx =>
      (for {
        item   <- OptionT(ctx.store.transact(RItem.findById(ctx.args.itemId)))
        attach <- OptionT.liftF(ctx.store.transact(RAttachment.findByItem(item.id)))
        asrc <-
          OptionT.liftF(ctx.store.transact(RAttachmentSource.findByItem(ctx.args.itemId)))
        asrcMap = asrc.map(s => s.id -> s).toMap
        // copy the original files over to attachments to run the default processing task
        // the processing doesn't touch the original files, only RAttachments
        attachSrc =
          attach
            .filter(contains(ctx))
            .flatMap(a =>
              asrcMap.get(a.id).map { src =>
                a.copy(fileId = src.fileId, name = src.name)
              }
            )
        _ <- OptionT.liftF(
          ctx.logger.debug(
            s"Loaded item and ${attachSrc.size} attachments to reprocess"
          )
        )
      } yield ItemData(
        item,
        attachSrc,
        Vector.empty,
        Vector.empty,
        asrcMap.view.mapValues(_.fileId).toMap,
        MetaProposalList.empty,
        Nil,
        MetaProposalList.empty,
        Nil
      )).getOrElseF(
        Sync[F].raiseError(new Exception(s"Item not found: ${ctx.args.itemId.id}"))
      )
    }

  def processFiles[F[_]: Async](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      data: ItemData
  ): Task[F, Args, ItemData] = {

    val convertArgs: Language => Args => F[ProcessItemArgs] =
      lang =>
        args =>
          ProcessItemArgs(
            ProcessItemArgs.ProcessMeta(
              data.item.cid,
              args.itemId.some,
              lang,
              None,             //direction
              data.item.source, //source-id
              None,             //folder
              Seq.empty,
              false,
              None,
              None,
              true
            ),
            Nil
          ).pure[F]

    getLanguage[F].flatMap { lang =>
      ProcessItem
        .processAttachments[F](cfg, fts, analyser, regexNer)(data)
        .flatMap(LinkProposal[F])
        .flatMap(SetGivenData[F](itemOps))
        .contramap[Args](convertArgs(lang))
    }
  }

  def getLanguage[F[_]: Sync]: Task[F, Args, Language] =
    Task { ctx =>
      (for {
        coll <- OptionT(ctx.store.transact(RCollective.findByItem(ctx.args.itemId)))
        lang = coll.language
      } yield lang).getOrElse(Language.German)
    }

  def isLastRetry[F[_]: Sync]: Task[F, Args, Boolean] =
    Task(_.isLastRetry)

  def safeProcess[F[_]: Async](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F]
  )(data: ItemData): Task[F, Args, ItemData] =
    isLastRetry[F].flatMap {
      case true =>
        processFiles[F](cfg, fts, itemOps, analyser, regexNer, data).attempt
          .flatMap {
            case Right(d) =>
              Task.pure(d)
            case Left(ex) =>
              logWarn[F](
                "Processing failed on last retry."
              ).andThen(_ => Sync[F].raiseError(ex))
          }
      case false =>
        processFiles[F](cfg, fts, itemOps, analyser, regexNer, data)
    }

  private def logWarn[F[_]](msg: => String): Task[F, Args, Unit] =
    Task(_.logger.warn(msg))
}
