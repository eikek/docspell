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
import docspell.scheduler.{Job, Task}
import docspell.store.Store

object MigrationTask {
  val taskName = Ident.unsafe("full-text-index")

  def apply[F[_]: Async](
      cfg: Config.FullTextSearch,
      store: Store[F],
      fts: FtsClient[F],
      createIndex: CreateIndex[F]
  ): Task[F, Unit, Unit] =
    Task
      .log[F, Unit](_.info(s"Running full-text-index migrations now"))
      .flatMap(_ =>
        Task(ctx =>
          for {
            migs <- migrationTasks[F](fts)
            res <- Migration[F](cfg, fts, store, createIndex, ctx.logger).run(migs)
          } yield res
        )
      )

  def onCancel[F[_]]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling full-text-index task"))

  def job[F[_]: Sync]: F[Job[String]] =
    Job
      .createNew(
        taskName,
        DocspellSystem.taskGroup,
        (),
        "Create full-text index",
        DocspellSystem.taskGroup,
        Priority.Low,
        Some(DocspellSystem.migrationTaskTracker)
      )
      .map(_.encode)

  def migrationTasks[F[_]: Async](fts: FtsClient[F]): F[List[Migration[F]]] =
    fts.initialize.map(_.map(fm => Migration.from(fm)))

}
