package docspell.joex.learn

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import fs2.Stream

import docspell.analysis.TextAnalyser
import docspell.analysis.nlp.ClassifierModel
import docspell.analysis.nlp.TextClassifier.Data
import docspell.backend.ops.OCollective
import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler._
import docspell.store.records.RClassifierSetting

object LearnClassifierTask {

  type Args = LearnClassifierArgs

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling learn-classifier task"))

  def apply[F[_]: Sync: ContextShift](
      cfg: Config.TextAnalysis,
      blocker: Blocker,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      (for {
        sett <- findActiveSettings[F](ctx, cfg)
        data = selectItems(
          ctx,
          math.min(cfg.classification.itemCount, sett.itemCount),
          sett.category.getOrElse("")
        )
        _ <- OptionT.liftF(
          analyser
            .classifier(blocker)
            .trainClassifier[Unit](ctx.logger, data)(Kleisli(handleModel(ctx)))
        )
      } yield ())
        .getOrElseF(logInactiveWarning(ctx.logger))
    }

  private def handleModel[F[_]](
      ctx: Context[F, Args]
  )(trainedModel: ClassifierModel): F[Unit] =
    ???

  private def selectItems[F[_]](
      ctx: Context[F, Args],
      max: Int,
      category: String
  ): Stream[F, Data] =
    ???

  private def findActiveSettings[F[_]: Sync](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    if (cfg.classification.enabled)
      OptionT(ctx.store.transact(RClassifierSetting.findById(ctx.args.collective)))
        .filter(_.enabled)
        .filter(_.category.nonEmpty)
        .map(OCollective.Classifier.fromRecord)
    else
      OptionT.none

  private def logInactiveWarning[F[_]: Sync](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Classification is disabled. Check joex config and the collective settings."
    )
}
