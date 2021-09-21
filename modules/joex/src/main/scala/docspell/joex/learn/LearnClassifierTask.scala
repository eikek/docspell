/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.backend.ops.OCollective
import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler._
import docspell.store.records.{RClassifierModel, RClassifierSetting}

object LearnClassifierTask {
  val pageSep = " --n-- "
  val noClass = "__NONE__"

  type Args = LearnClassifierArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling learn-classifier task"))

  def apply[F[_]: Async](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    learnTags(cfg, analyser)
      .flatMap(_ => learnItemEntities(cfg, analyser))
      .flatMap(_ => Task(_ => Sync[F].delay(System.gc())))

  private def learnItemEntities[F[_]: Async](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      if (cfg.classification.enabled)
        LearnItemEntities
          .learnAll(
            analyser,
            ctx.args.collective,
            cfg.classification.itemCount,
            cfg.maxLength
          )
          .run(ctx)
      else ().pure[F]
    }

  private def learnTags[F[_]: Async](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      val learnTags =
        for {
          sett <- findActiveSettings[F](ctx, cfg)
          maxItems = cfg.classification.itemCountOrWhenLower(sett.itemCount)
          _ <- OptionT.liftF(
            LearnTags
              .learnAllTagCategories(analyser)(
                ctx.args.collective,
                maxItems,
                cfg.maxLength
              )
              .run(ctx)
          )
        } yield ()
      // learn classifier models from active tag categories
      learnTags.getOrElseF(logInactiveWarning(ctx.logger)) *>
        // delete classifier model files for categories that have been removed
        clearObsoleteTagModels(ctx) *>
        // when tags are deleted, categories may get removed. fix the json array
        ctx.store
          .transact(RClassifierSetting.fixCategoryList(ctx.args.collective))
          .map(_ => ())
    }

  private def clearObsoleteTagModels[F[_]: Sync](ctx: Context[F, Args]): F[Unit] =
    for {
      list <- ctx.store.transact(
        ClassifierName.findOrphanTagModels(ctx.args.collective)
      )
      _ <- ctx.logger.info(
        s"Found ${list.size} obsolete model files that are deleted now."
      )
      n <- ctx.store.transact(RClassifierModel.deleteAll(list.map(_.id)))
      _ <- list
        .map(_.fileId)
        .traverse(id => ctx.store.fileStore.delete(id))
      _ <- ctx.logger.debug(s"Deleted $n model files.")
    } yield ()

  private def findActiveSettings[F[_]: Sync](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    if (cfg.classification.enabled)
      OptionT(ctx.store.transact(RClassifierSetting.findById(ctx.args.collective)))
        .filter(_.autoTagEnabled)
        .map(OCollective.Classifier.fromRecord)
    else
      OptionT.none

  private def logInactiveWarning[F[_]](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Auto-tagging is disabled. Check joex config and the collective settings."
    )
}
