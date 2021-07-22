/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.records._

import com.github.eikek.calev._

object HouseKeepingTask {
  private val periodicId = Ident.unsafe("docspell-houskeeping")

  val taskName: Ident = Ident.unsafe("housekeeping")

  def apply[F[_]: Async](cfg: Config): Task[F, Unit, Unit] =
    Task
      .log[F, Unit](_.info(s"Running house-keeping task now"))
      .flatMap(_ => CleanupInvitesTask(cfg.houseKeeping.cleanupInvites))
      .flatMap(_ => CleanupRememberMeTask(cfg.houseKeeping.cleanupRememberMe))
      .flatMap(_ => CleanupJobsTask(cfg.houseKeeping.cleanupJobs))
      .flatMap(_ => CheckNodesTask(cfg.houseKeeping.checkNodes))

  def onCancel[F[_]]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling house-keeping task"))

  def periodicTask[F[_]: Sync](ce: CalEvent): F[RPeriodicTask] =
    RPeriodicTask
      .createJson(
        true,
        taskName,
        DocspellSystem.taskGroup,
        (),
        "Docspell house-keeping",
        DocspellSystem.taskGroup,
        Priority.Low,
        ce,
        None
      )
      .map(_.copy(id = periodicId))
}
