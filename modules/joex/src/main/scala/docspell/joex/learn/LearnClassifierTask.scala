/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.analysis.TextAnalyser
import docspell.backend.ops.OCollective
import docspell.common._
import docspell.joex.Config
import docspell.logging.Logger
import docspell.scheduler._
import docspell.store.Store
import docspell.store.records.{RClassifierModel, RClassifierSetting}

object LearnClassifierTask {
  val pageSep = " --n-- "
  val noClass = "__NONE__"

  type Args = LearnClassifierArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling learn-classifier task"))

  def apply[F[_]: Async: Files](
      cfg: Config.TextAnalysis,
      store: Store[F],
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    learnTags(cfg, store, analyser)
      .flatMap(_ => learnItemEntities(cfg, store, analyser))
      .flatMap(_ => Task(_ => Sync[F].delay(System.gc())))

  private def learnItemEntities[F[_]: Async: Files](
      cfg: Config.TextAnalysis,
      store: Store[F],
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      if (cfg.classification.enabled)
        LearnItemEntities
          .learnAll(
            analyser,
            store,
            ctx.args.collectiveId,
            cfg.classification.itemCount,
            cfg.maxLength
          )
          .run(ctx)
      else ().pure[F]
    }

  private def learnTags[F[_]: Async: Files](
      cfg: Config.TextAnalysis,
      store: Store[F],
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      val learnTags =
        for {
          sett <- findActiveSettings[F](ctx, store, cfg)
          maxItems = cfg.classification.itemCountOrWhenLower(sett.itemCount)
          _ <- OptionT.liftF(
            LearnTags
              .learnAllTagCategories(analyser, store)(
                ctx.args.collectiveId,
                maxItems,
                cfg.maxLength
              )
              .run(ctx)
          )
        } yield ()
      // learn classifier models from active tag categories
      learnTags.getOrElseF(logInactiveWarning(ctx.logger)) *>
        // delete classifier model files for categories that have been removed
        clearObsoleteTagModels(ctx, store) *>
        // when tags are deleted, categories may get removed. fix the json array
        store
          .transact(RClassifierSetting.fixCategoryList(ctx.args.collectiveId))
          .map(_ => ())
    }

  private def clearObsoleteTagModels[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F]
  ): F[Unit] =
    for {
      list <- store.transact(
        ClassifierName.findOrphanTagModels(ctx.args.collectiveId)
      )
      _ <- ctx.logger.info(
        s"Found ${list.size} obsolete model files that are deleted now."
      )
      n <- store.transact(RClassifierModel.deleteAll(list.map(_.id)))
      _ <- list
        .map(_.fileId)
        .traverse(id => store.fileRepo.delete(id))
      _ <- ctx.logger.debug(s"Deleted $n model files.")
    } yield ()

  private def findActiveSettings[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    if (cfg.classification.enabled)
      OptionT(store.transact(RClassifierSetting.findById(ctx.args.collectiveId)))
        .filter(_.autoTagEnabled)
        .map(OCollective.Classifier.fromRecord)
    else
      OptionT.none

  private def logInactiveWarning[F[_]](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Auto-tagging is disabled. Check joex config and the collective settings."
    )
}
