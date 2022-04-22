/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import cats.effect._
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.addons.AddonExecutorConfig.{NSpawn, NixConfig}
import docspell.addons._
import docspell.addons.runner.NixFlakeRunner.PreCtx
import docspell.common.Duration
import docspell.common.exec._
import docspell.logging.Logger

final class NixFlakeRunner[F[_]: Async](cfg: NixFlakeRunner.Config)
    extends AddonRunner[F] {

  val runnerType = List(RunnerType.NixFlake)

  def run(
      logger: Logger[F],
      env: Env,
      ctx: Context
  ): F[AddonResult] =
    prepare(logger, ctx)
      .flatMap { preCtx =>
        if (preCtx.nspawnEnabled) runInContainer(logger, env, preCtx, ctx)
        else runOnHost(logger, env, preCtx, ctx)
      }

  def prepare(logger: Logger[F], ctx: Context): F[PreCtx] =
    for {
      _ <- logger.info(s"Prepare addon ${ctx.meta.nameAndVersion} for executing via nix")
      _ <- logger.debug(s"Building with nix build")
      _ <- SysExec(cfg.nixBuild, logger, workdir = ctx.addonDir.some)
        .flatMap(_.logOutputs(logger, "nix build"))
        .use(_.waitFor())
      bin <- findFile(ctx.addonDir / "result" / "bin", ctx.addonDir / "result")
      _ <- logger.debug(s"Build done, found binary: $bin")
      _ <- logger.debug(s"Checking for systemd-nspawn…")
      cnt <- checkContainer(logger)
      _ <-
        if (cnt)
          logger.debug(s"Using systemd-nspawn to run addon in a container.")
        else
          logger.info(s"Running via systemd-nspawn is disabled in the config file")
    } yield PreCtx(cnt, ctx.baseDir.relativize(bin))

  private def checkContainer(logger: Logger[F]): F[Boolean] =
    if (!cfg.nspawn.enabled) false.pure[F]
    else RunnerUtil.checkContainer(logger, cfg.nspawn)

  private def runOnHost(
      logger: Logger[F],
      env: Env,
      preCtx: PreCtx,
      ctx: Context
  ): F[AddonResult] = {
    val cmd =
      SysCmd(preCtx.binary.toString, Args.empty).withTimeout(cfg.timeout).addEnv(env)
    RunnerUtil.runDirectly(logger, ctx)(cmd)
  }

  private def runInContainer(
      logger: Logger[F],
      env: Env,
      preCtx: PreCtx,
      ctx: Context
  ): F[AddonResult] = {
    val cmd = SysCmd(preCtx.binary.toString, Args.empty)
      .withTimeout(cfg.timeout)
      .addEnv(env)
    RunnerUtil.runInContainer(logger, cfg.nspawn, ctx)(cmd)
  }

  /** Find first file, try directories in given order. */
  private def findFile(firstDir: Path, more: Path*): F[Path] = {
    val fail: F[Path] = Sync[F].raiseError(
      new NoSuchElementException(
        s"No file found to execute in ${firstDir :: more.toList}"
      )
    )

    Stream
      .emits(more)
      .cons1(firstDir)
      .flatMap(dir =>
        Files[F]
          .list(dir)
          .evalFilter(p => Files[F].isDirectory(p).map(!_))
          .take(1)
      )
      .take(1)
      .compile
      .last
      .flatMap(_.fold(fail)(Sync[F].pure))
  }
}

object NixFlakeRunner {
  def apply[F[_]: Async](cfg: AddonExecutorConfig): NixFlakeRunner[F] =
    new NixFlakeRunner[F](Config(cfg.nixRunner, cfg.nspawn, cfg.runTimeout))

  case class Config(
      nix: NixConfig,
      nspawn: NSpawn,
      timeout: Duration
  ) {

    val nixBuild =
      SysCmd(nix.nixBinary, Args.of("build")).withTimeout(nix.buildTimeout)

    val nspawnVersion = nspawn.nspawnVersion
  }

  case class PreCtx(nspawnEnabled: Boolean, binary: Path)
}
