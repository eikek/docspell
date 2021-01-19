package docspell.joex.learn

import cats.data.Kleisli
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

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling learn-classifier task"))

  def apply[F[_]: Sync: ContextShift](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      val learnTags =
        for {
          sett <- findActiveSettings[F](ctx, cfg)
          maxItems = math.min(cfg.classification.itemCount, sett.itemCount)
          _ <- OptionT.liftF(
            learnAllTagCategories(analyser)(ctx.args.collective, maxItems).run(ctx)
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

  def learnTagCategory[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  )(
      category: String
  ): Task[F, A, Unit] =
    Task { ctx =>
      val data = SelectItems.forCategory(ctx, collective)(maxItems, category)
      ctx.logger.info(s"Learn classifier for tag category: $category") *>
        analyser.classifier.trainClassifier(ctx.logger, data)(
          Kleisli(
            StoreClassifierModel.handleModel(
              ctx,
              collective,
              ClassifierName.tagCategory(category)
            )
          )
        )
    }

  def learnAllTagCategories[F[_]: Sync: ContextShift, A](analyser: TextAnalyser[F])(
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    Task { ctx =>
      for {
        cats <- ctx.store.transact(RClassifierSetting.getActiveCategories(collective))
        task = learnTagCategory[F, A](analyser, collective, maxItems) _
        _ <- cats.map(task).traverse(_.run(ctx))
      } yield ()
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
        .map(_.fileId.id)
        .traverse(id => ctx.store.bitpeace.delete(id).compile.drain)
      _ <- ctx.logger.debug(s"Deleted $n model files.")
    } yield ()

  private def findActiveSettings[F[_]: Sync](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    if (cfg.classification.enabled)
      OptionT(ctx.store.transact(RClassifierSetting.findById(ctx.args.collective)))
        .filter(_.enabled)
        .map(OCollective.Classifier.fromRecord)
    else
      OptionT.none

  private def logInactiveWarning[F[_]: Sync](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Auto-tagging is disabled. Check joex config and the collective settings."
    )
}
