package docspell.joex.learn

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.analysis.TextAnalyser
import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._
import docspell.joex.scheduler._

object LearnItemEntities {
  def learnAll[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learnCorrOrg(analyser, collective, maxItems, maxTextLen)
      .flatMap(_ => learnCorrPerson[F, A](analyser, collective, maxItems, maxTextLen))
      .flatMap(_ => learnConcPerson(analyser, collective, maxItems, maxTextLen))
      .flatMap(_ => learnConcEquip(analyser, collective, maxItems, maxTextLen))

  def learnCorrOrg[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.correspondentOrg,
      ctx => SelectItems.forCorrOrg(ctx.store, collective, maxItems, maxTextLen)
    )

  def learnCorrPerson[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.correspondentPerson,
      ctx => SelectItems.forCorrPerson(ctx.store, collective, maxItems, maxTextLen)
    )

  def learnConcPerson[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.concernedPerson,
      ctx => SelectItems.forConcPerson(ctx.store, collective, maxItems, maxTextLen)
    )

  def learnConcEquip[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.concernedEquip,
      ctx => SelectItems.forConcEquip(ctx.store, collective, maxItems, maxTextLen)
    )

  private def learn[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident
  )(cname: ClassifierName, data: Context[F, _] => Stream[F, Data]): Task[F, A, Unit] =
    Task { ctx =>
      ctx.logger.info(s"Learn classifier ${cname.name}") *>
        analyser.classifier.trainClassifier(ctx.logger, data(ctx))(
          Kleisli(StoreClassifierModel.handleModel(ctx, collective, cname))
        )
    }
}
