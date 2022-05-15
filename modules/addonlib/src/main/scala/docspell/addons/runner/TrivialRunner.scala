/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import cats.data.OptionT
import cats.effect._
import cats.kernel.Monoid
import cats.syntax.all._
import fs2.io.file.PosixPermission._
import fs2.io.file.{Files, PosixPermissions}

import docspell.addons.AddonExecutorConfig.NSpawn
import docspell.addons._
import docspell.common.Duration
import docspell.common.exec.{Args, Env, SysCmd}
import docspell.logging.Logger

final class TrivialRunner[F[_]: Async](cfg: TrivialRunner.Config) extends AddonRunner[F] {
  private val sync = Async[F]
  private val files = Files[F]
  implicit val andMonoid: Monoid[Boolean] = Monoid.instance[Boolean](true, _ && _)

  private val executeBits = PosixPermissions(
    OwnerExecute,
    OwnerRead,
    OwnerWrite,
    GroupExecute,
    GroupRead,
    OthersExecute,
    OthersRead
  )

  val runnerType = List(RunnerType.Trivial)

  def run(
      logger: Logger[F],
      env: Env,
      ctx: Context
  ) = {
    val binaryPath = ctx.meta.runner
      .flatMap(_.trivial)
      .map(_.exec)
      .map(bin => ctx.addonDir / bin)

    binaryPath match {
      case None =>
        sync.raiseError(new IllegalStateException("No executable specified in addon!"))

      case Some(file) =>
        val bin = ctx.baseDir.relativize(file)
        val cmd = SysCmd(bin.toString, Args.empty).withTimeout(cfg.timeout).addEnv(env)

        val withNSpawn =
          OptionT
            .whenF(cfg.nspawn.enabled)(RunnerUtil.checkContainer(logger, cfg.nspawn))
            .getOrElse(false)

        files.setPosixPermissions(file, executeBits).attempt *>
          withNSpawn.flatMap {
            case true =>
              RunnerUtil.runInContainer(logger, cfg.nspawn, ctx)(cmd)
            case false =>
              RunnerUtil.runDirectly(logger, ctx)(cmd)
          }
    }
  }
}

object TrivialRunner {
  def apply[F[_]: Async](cfg: AddonExecutorConfig): TrivialRunner[F] =
    new TrivialRunner[F](Config(cfg.nspawn, cfg.runTimeout))

  case class Config(nspawn: NSpawn, timeout: Duration)
}
