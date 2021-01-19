package docspell.joex.learn

import cats.data.Kleisli
import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.common._
import docspell.joex.scheduler._
import docspell.store.records.RClassifierSetting

object LearnTags {

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
}
