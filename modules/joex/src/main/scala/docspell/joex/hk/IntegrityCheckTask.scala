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
import docspell.joex.filecopy.FileIntegrityCheckTask
import docspell.scheduler.Task
import docspell.store.Store

object IntegrityCheckTask {

  def apply[F[_]: Sync](
      cfg: HouseKeepingConfig.IntegrityCheck,
      store: Store[F],
      fileRepo: OFileRepository[F]
  ): Task[F, Unit, FileIntegrityCheckTask.Result] =
    Task { ctx =>
      if (cfg.enabled)
        FileIntegrityCheckTask(fileRepo, store).run(
          ctx.map(_ => FileIntegrityCheckArgs(FileKeyPart.Empty))
        )
      else
        ctx.logger.info("Integrity check task is disabled in the configuration") *>
          FileIntegrityCheckTask.Result.empty.pure[F]
    }
}
