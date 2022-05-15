/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.addon

import cats.effect._
import cats.syntax.all._

import docspell.addons.Middleware
import docspell.backend.joex.{AddonOps, LoggerExtension}
import docspell.backend.ops.OAddons
import docspell.common.{Ident, ScheduledAddonTaskArgs}
import docspell.scheduler.Task

object ScheduledAddonTask extends AddonTaskExtension with LoggerExtension {
  type Args = ScheduledAddonTaskArgs

  val name: Ident = OAddons.scheduledAddonTaskName

  def apply[F[_]: Async](ops: AddonOps[F]): Task[F, Args, Result] =
    Task { ctx =>
      for {
        execRes <- ops.execById(ctx.args.collective, ctx.args.addonTaskId, ctx.logger)(
          Middleware.identity[F]
        )
        _ <- execRes.result.combineAll.raiseErrorIfNeeded[F]
      } yield Result(
        execRes.result.combineAll.addonResult,
        execRes.runConfigs.flatMap(_.refs.map(_.archive.nameAndVersion))
      )
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${name.id} task"))

}
