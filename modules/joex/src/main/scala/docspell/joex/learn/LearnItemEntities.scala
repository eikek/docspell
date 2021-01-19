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
  def learnAll[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    learnCorrOrg(analyser, collective, maxItems)
      .flatMap(_ => learnCorrPerson[F, A](analyser, collective, maxItems))
      .flatMap(_ => learnConcPerson(analyser, collective, maxItems))
      .flatMap(_ => learnConcEquip(analyser, collective, maxItems))

  def learnCorrOrg[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.correspondentOrg,
      ctx => SelectItems.forCorrOrg(ctx.store, collective, maxItems)
    )

  def learnCorrPerson[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.correspondentPerson,
      ctx => SelectItems.forCorrPerson(ctx.store, collective, maxItems)
    )

  def learnConcPerson[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.concernedPerson,
      ctx => SelectItems.forConcPerson(ctx.store, collective, maxItems)
    )

  def learnConcEquip[F[_]: Sync: ContextShift, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int
  ): Task[F, A, Unit] =
    learn(analyser, collective)(
      ClassifierName.concernedEquip,
      ctx => SelectItems.forConcEquip(ctx.store, collective, maxItems)
    )

  private def learn[F[_]: Sync: ContextShift, A](
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
