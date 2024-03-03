/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.addons.AddonTriggerType
import docspell.analysis.TextAnalyser
import docspell.backend.joex.AddonOps
import docspell.backend.ops.OItem
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.scheduler.Context
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.queries.QItem
import docspell.store.records.RAttachment
import docspell.store.records.RAttachmentSource
import docspell.store.records.RCollective
import docspell.store.records.RItem

object ReProcessItem {
  type Args = ReProcessItemArgs

  def apply[F[_]: Async: Files](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      addonOps: AddonOps[F],
      store: Store[F]
  ): Task[F, Args, Unit] =
    Task
      .log[F, Args](_.info("===== Start reprocessing ======"))
      .flatMap(_ =>
        loadItem[F](store)
          .flatMap(
            safeProcess[F](
              cfg,
              fts,
              itemOps,
              analyser,
              regexNer,
              addonOps,
              store
            )
          )
          .map(_ => ())
      )

  def onCancel[F[_]]: Task[F, Args, Unit] =
    logWarn("Now cancelling re-processing.")

  // --- Helpers

  private def contains[F[_]](ctx: Context[F, Args]): RAttachment => Boolean = {
    val selection = ctx.args.attachments.toSet
    if (selection.isEmpty) _ => true
    else ra => selection.contains(ra.id)
  }

  def loadItem[F[_]: Sync](store: Store[F]): Task[F, Args, ItemData] =
    Task { ctx =>
      (for {
        item <- OptionT(store.transact(RItem.findById(ctx.args.itemId)))
        attach <- OptionT.liftF(store.transact(RAttachment.findByItem(item.id)))
        asrc <-
          OptionT.liftF(store.transact(RAttachmentSource.findByItem(ctx.args.itemId)))
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
        Nil,
        None // cannot retain customData from an already existing item
      )).getOrElseF(
        Sync[F].raiseError(new Exception(s"Item not found: ${ctx.args.itemId.id}"))
      )
    }

  def processFiles[F[_]: Async: Files](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      addonOps: AddonOps[F],
      store: Store[F],
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
              None, // direction
              data.item.source, // source-id
              None, // folder
              Seq.empty,
              skipDuplicate = false,
              None,
              None,
              reprocess = true,
              None, // attachOnly (not used when reprocessing attachments)
              None // cannot retain customData from an already existing item
            ),
            Nil
          ).pure[F]

    getLanguage[F](store).flatMap { lang =>
      ProcessItem
        .processAttachments[F](cfg, fts, analyser, regexNer, store)(data)
        .flatMap(LinkProposal[F](store))
        .flatMap(SetGivenData[F](itemOps))
        .flatMap(RunAddons[F](addonOps, store, AddonTriggerType.FinalReprocessItem))
        .contramap[Args](convertArgs(lang))
    }
  }

  def getLanguage[F[_]: Sync](store: Store[F]): Task[F, Args, Language] =
    Task { ctx =>
      val lang1 = OptionT(
        store.transact(QItem.getItemLanguage(ctx.args.itemId)).map(_.headOption)
      )
      val lang2 = OptionT(store.transact(RCollective.findByItem(ctx.args.itemId)))
        .map(_.language)

      lang1.orElse(lang2).getOrElse(Language.German)
    }

  def isLastRetry[F[_]]: Task[F, Args, Boolean] =
    Task(_.isLastRetry)

  def safeProcess[F[_]: Async: Files](
      cfg: Config,
      fts: FtsClient[F],
      itemOps: OItem[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F],
      addonOps: AddonOps[F],
      store: Store[F]
  )(data: ItemData): Task[F, Args, ItemData] =
    isLastRetry[F].flatMap {
      case true =>
        processFiles[F](
          cfg,
          fts,
          itemOps,
          analyser,
          regexNer,
          addonOps,
          store,
          data
        ).attempt
          .flatMap {
            case Right(d) =>
              Task.pure(d)
            case Left(ex) =>
              logWarn[F](
                "Processing failed on last retry."
              ).andThen(_ => Sync[F].raiseError(ex))
          }
      case false =>
        processFiles[F](
          cfg,
          fts,
          itemOps,
          analyser,
          regexNer,
          addonOps,
          store,
          data
        )
    }

  private def logWarn[F[_]](msg: => String): Task[F, Args, Unit] =
    Task(_.logger.warn(msg))
}
