/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._
import fs2.io.net.Network

import docspell.backend.ops.{ODownloadAll, OFileRepository}
import docspell.common._
import docspell.joex.Config
import docspell.joex.filecopy.FileIntegrityCheckTask
import docspell.scheduler.usertask.UserTask
import docspell.scheduler.{JobTaskResultEncoder, Task}
import docspell.store.Store

import com.github.eikek.calev._
import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

object HouseKeepingTask {
  private val periodicId = Ident.unsafe("docspell-houskeeping")

  val taskName: Ident = Ident.unsafe("housekeeping")

  def apply[F[_]: Async: Network](
      cfg: Config,
      store: Store[F],
      fileRepo: OFileRepository[F],
      downloadAll: ODownloadAll[F]
  ): Task[F, Unit, Result] = {
    val combined =
      (
        CheckNodesTask(cfg.houseKeeping.checkNodes, store),
        CleanupInvitesTask(cfg.houseKeeping.cleanupInvites, store),
        CleanupJobsTask(cfg.houseKeeping.cleanupJobs, store),
        CleanupRememberMeTask(cfg.houseKeeping.cleanupRememberMe, store),
        CleanupDownloadsTask(cfg.houseKeeping.cleanupDownloads, downloadAll),
        IntegrityCheckTask(cfg.houseKeeping.integrityCheck, store, fileRepo)
      ).mapN(Result.apply)

    Task
      .log[F, Unit](_.info(s"Running house-keeping task now"))
      .flatMap(_ => combined)
  }

  def onCancel[F[_]]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling house-keeping task"))

  def periodicTask[F[_]: Sync](ce: CalEvent): F[UserTask[Unit]] =
    UserTask(
      periodicId,
      taskName,
      enabled = true,
      ce,
      "Docspell house-keeping".some,
      ()
    ).pure[F]

  case class Result(
      checkNodes: CleanupResult,
      cleanupInvites: CleanupResult,
      cleanupJobs: CleanupResult,
      cleanupRememberMe: CleanupResult,
      cleanupDownloads: CleanupResult,
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
          s"- Downloads remove: ${r.cleanupDownloads.asString}\n" +
          s"- Integrity check: ok=${r.integrityCheck.ok}, failed=${r.integrityCheck.failedKeys.size}, notFound=${r.integrityCheck.notFoundKeys.size}"
      }

  }
}
