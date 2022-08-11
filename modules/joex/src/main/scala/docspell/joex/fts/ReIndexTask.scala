/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.fts

import cats.effect._
import cats.implicits._

import docspell.backend.fulltext.CreateIndex
import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.fts.FtsWork.syntax._
import docspell.scheduler.Task
import docspell.store.Store

object ReIndexTask {
  type Args = ReIndexTaskArgs

  val taskName = ReIndexTaskArgs.taskName
  val tracker = DocspellSystem.migrationTaskTracker

  def apply[F[_]: Async](
      cfg: Config.FullTextSearch,
      store: Store[F],
      fts: FtsClient[F],
      fulltext: CreateIndex[F]
  ): Task[F, Args, Unit] =
    Task
      .log[F, Args](_.info(s"Running full-text re-index now"))
      .flatMap(_ =>
        Task(ctx =>
          clearData[F](ctx.args.collective).forContext(cfg, store, fts, fulltext).run(ctx)
        )
      )

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log[F, Args](_.warn("Cancelling full-text re-index task"))

  private def clearData[F[_]: Async](collective: Option[CollectiveId]): FtsWork[F] =
    FtsWork.log[F](_.info("Clearing index data")) ++
      (collective match {
        case Some(_) =>
          FtsWork
            .clearIndex[F](collective)
            .recoverWith(
              FtsWork.log[F](_.info("Clearing data failed. Continue re-indexing."))
            ) ++
            FtsWork.log[F](_.info("Inserting data from database")) ++
            FtsWork.insertAll[F](collective)

        case None =>
          FtsWork.log[F](_.info("Running re-create index")) ++
            FtsWork.reInitializeTasks[F]
      })
}
