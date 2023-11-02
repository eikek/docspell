/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.analysis.TextAnalyser
import docspell.common._
import docspell.scheduler._
import docspell.store.Store
import docspell.store.records.RClassifierSetting

object LearnTags {

  def learnTagCategory[F[_]: Async: Files, A](
      analyser: TextAnalyser[F],
      store: Store[F],
      collective: CollectiveId,
      maxItems: Int,
      maxTextLen: Int
  )(
      category: String
  ): Task[F, A, Unit] =
    Task { ctx =>
      val data =
        SelectItems.forCategory(store, collective)(maxItems, category, maxTextLen)
      ctx.logger.info(s"Learn classifier for tag category: $category") *>
        analyser.classifier.trainClassifier(ctx.logger, data)(
          Kleisli(
            StoreClassifierModel.handleModel(
              store,
              ctx.logger,
              collective,
              ClassifierName.tagCategory(category)
            )
          )
        )
    }

  def learnAllTagCategories[F[_]: Async: Files, A](
      analyser: TextAnalyser[F],
      store: Store[F]
  )(
      collective: CollectiveId,
      maxItems: Int,
      maxTextLen: Int
  ): Task[F, A, Unit] =
    Task { ctx =>
      for {
        cats <- store.transact(RClassifierSetting.getActiveCategories(collective))
        task = learnTagCategory[F, A](analyser, store, collective, maxItems, maxTextLen) _
        _ <- cats.map(task).traverse(_.run(ctx))
      } yield ()
    }
}
