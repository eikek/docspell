/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.fts

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.records.RJob

object MigrationTask {
  val taskName = Ident.unsafe("full-text-index")

  def apply[F[_]: Async](
      cfg: Config.FullTextSearch,
      fts: FtsClient[F]
  ): Task[F, Unit, Unit] =
    Task
      .log[F, Unit](_.info(s"Running full-text-index migrations now"))
      .flatMap(_ =>
        Task(ctx =>
          for {
            migs <- migrationTasks[F](fts)
            res  <- Migration[F](cfg, fts, ctx.store, ctx.logger).run(migs)
          } yield res
        )
      )

  def onCancel[F[_]]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling full-text-index task"))

  def job[F[_]: Sync]: F[RJob] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      taskName,
      DocspellSystem.taskGroup,
      (),
      "Create full-text index",
      now,
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.migrationTaskTracker)
    )

  def migrationTasks[F[_]: Async](fts: FtsClient[F]): F[List[Migration[F]]] =
    fts.initialize.map(_.map(fm => Migration.from(fm)))

}
