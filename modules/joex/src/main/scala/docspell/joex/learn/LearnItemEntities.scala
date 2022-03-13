/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.analysis.TextAnalyser
import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._
import docspell.scheduler._
import docspell.store.Store

object LearnItemEntities {
  def learnAll[F[_]: Async, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learnCorrOrg[F, A](analyser, store, collective, maxItems, maxTextLen)
      .flatMap(_ =>
        learnCorrPerson[F, A](analyser, store, collective, maxItems, maxTextLen)
      )
      .flatMap(_ => learnConcPerson(analyser, store, collective, maxItems, maxTextLen))
      .flatMap(_ => learnConcEquip(analyser, store, collective, maxItems, maxTextLen))

  def learnCorrOrg[F[_]: Async, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(store, analyser, collective)(
      ClassifierName.correspondentOrg,
      _ => SelectItems.forCorrOrg(store, collective, maxItems, maxTextLen)
    )

  def learnCorrPerson[F[_]: Async, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(store, analyser, collective)(
      ClassifierName.correspondentPerson,
      _ => SelectItems.forCorrPerson(store, collective, maxItems, maxTextLen)
    )

  def learnConcPerson[F[_]: Async, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(store, analyser, collective)(
      ClassifierName.concernedPerson,
      _ => SelectItems.forConcPerson(store, collective, maxItems, maxTextLen)
    )

  def learnConcEquip[F[_]: Async, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    learn(store, analyser, collective)(
      ClassifierName.concernedEquip,
      _ => SelectItems.forConcEquip(store, collective, maxItems, maxTextLen)
    )

  private def learn[F[_]: Async, A](
      store: Store[F],
      analyser: TextAnalyser[F],
      collective: Ident
  )(cname: ClassifierName, data: Context[F, _] => Stream[F, Data]): Task[F, A, Unit] =
    Task { ctx =>
      ctx.logger.info(s"Learn classifier ${cname.name}") *>
        analyser.classifier.trainClassifier(ctx.logger, data(ctx))(
          Kleisli(StoreClassifierModel.handleModel(store, ctx.logger, collective, cname))
        )
    }
}
