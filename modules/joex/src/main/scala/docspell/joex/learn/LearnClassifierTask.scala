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

object LearnClassifierTask {

  type Args = LearnClassifierArgs

  def apply[F[_]: Sync: ContextShift](
      cfg: Config.TextAnalysis,
      blocker: Blocker,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      (for {
        sett <- findActiveSettings[F](ctx.args.collective, cfg)
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
      coll: Ident,
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    ???

  private def logInactiveWarning[F[_]: Sync](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Classification is disabled. Check joex config and the collective settings."
    )
}
