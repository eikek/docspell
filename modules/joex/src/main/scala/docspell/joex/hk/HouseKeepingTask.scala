/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.backend.ops.OFileRepository
import docspell.common._
import docspell.joex.Config
import docspell.joex.filecopy.FileIntegrityCheckTask
import docspell.scheduler.{JobTaskResultEncoder, Task}
import docspell.store.records._
import docspell.store.usertask.UserTaskScope

import com.github.eikek.calev._
import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

object HouseKeepingTask {
  private val periodicId = Ident.unsafe("docspell-houskeeping")

  val taskName: Ident = Ident.unsafe("housekeeping")

  def apply[F[_]: Async](
      cfg: Config,
      fileRepo: OFileRepository[F]
  ): Task[F, Unit, Result] = {
    val combined =
      (
        CheckNodesTask(cfg.houseKeeping.checkNodes),
        CleanupInvitesTask(cfg.houseKeeping.cleanupInvites),
        CleanupJobsTask(cfg.houseKeeping.cleanupJobs),
        CleanupRememberMeTask(cfg.houseKeeping.cleanupRememberMe),
        IntegrityCheckTask(cfg.houseKeeping.integrityCheck, fileRepo)
      ).mapN(Result.apply)

    Task
      .log[F, Unit](_.info(s"Running house-keeping task now"))
      .flatMap(_ => combined)
  }

  def onCancel[F[_]]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling house-keeping task"))

  def periodicTask[F[_]: Sync](ce: CalEvent): F[RPeriodicTask] =
    RPeriodicTask
      .createJson(
        true,
        UserTaskScope(DocspellSystem.taskGroup),
        taskName,
        (),
        "Docspell house-keeping",
        Priority.Low,
        ce,
        None
      )
      .map(_.copy(id = periodicId))

  case class Result(
      checkNodes: CleanupResult,
      cleanupInvites: CleanupResult,
      cleanupJobs: CleanupResult,
      cleanupRememberMe: CleanupResult,
      integrityCheck: FileIntegrityCheckTask.Result
  )

  object Result {
    implicit val jsonEncoder: Encoder[Result] =
      deriveEncoder

    implicit val jobTaskResultEncoder: JobTaskResultEncoder[Result] =
      JobTaskResultEncoder.fromJson[Result].withMessage { r =>
        s"- Nodes removed: ${r.checkNodes.asString}\n" +
          s"- Invites removed: ${r.cleanupInvites.asString}\n" +
          s"- Jobs removed: ${r.cleanupJobs.asString}\n" +
          s"- RememberMe removed: ${r.cleanupRememberMe.asString}\n" +
          s"- Integrity check: ok=${r.integrityCheck.ok}, failed=${r.integrityCheck.failedKeys.size}, notFound=${r.integrityCheck.notFoundKeys.size}"
      }

  }
}
