/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.Kleisli
import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.common._
import docspell.scheduler._
import docspell.store.records.RClassifierSetting

object LearnTags {

  def learnTagCategory[F[_]: Async, A](
      analyser: TextAnalyser[F],
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  )(
      category: String
  ): Task[F, A, Unit] =
    Task { ctx =>
      val data = SelectItems.forCategory(ctx, collective)(maxItems, category, maxTextLen)
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

  def learnAllTagCategories[F[_]: Async, A](analyser: TextAnalyser[F])(
      collective: Ident,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    Task { ctx =>
      for {
        cats <- ctx.store.transact(RClassifierSetting.getActiveCategories(collective))
        task = learnTagCategory[F, A](analyser, collective, maxItems, maxTextLen) _
        _ <- cats.map(task).traverse(_.run(ctx))
      } yield ()
    }
}
