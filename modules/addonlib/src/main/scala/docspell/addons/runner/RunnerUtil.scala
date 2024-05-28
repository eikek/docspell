/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import cats.data.OptionT
import cats.effect.{Async, Sync}
import cats.syntax.all._
import fs2.Pipe
import fs2.io.file.Files

import docspell.addons._
import docspell.addons.out.AddonOutput
import docspell.common.exec.{SysCmd, SysExec}
import docspell.common.util.Random
import docspell.logging.Logger

import io.circe.{parser => JsonParser}

private[addons] object RunnerUtil {

  /** Run the given `cmd` on this machine.
    *
    * The `cmd` is containing a template command to execute the addon. The path are
    * expected to be relative to the `ctx.baseDir`. Additional arguments and environment
    * variables are added as configured in the addon.
    */
  def runDirectly[F[_]: Async](
      logger: Logger[F],
      ctx: Context
  )(cmd: SysCmd): F[AddonResult] = {
    val addonCmd = ctx
      .addonCommand(cmd.program, cmd.timeout, relativeToBase = false, None, None)
      .withArgs(_.append(cmd.args))
      .addEnv(cmd.env)
    runAddonCommand(logger, addonCmd, ctx)
  }

  /** Run the given `cmd` inside a container via systemd-nspawn.
    *
    * The `cmd` is containing a template command to execute the addon. The path are
    * expected to be relative to the `ctx.baseDir`. Additional arguments and environment
    * variables are added as configured in the addon.
    */
  def runInContainer[F[_]: Async: Files](
      logger: Logger[F],
      cfg: AddonExecutorConfig.NSpawn,
      ctx: Context
  )(cmd: SysCmd): F[AddonResult] = {
    val outputPath = "/mnt/output"
    val cachePath = "/mnt/cache"
    val addonCmd = ctx
      .addonCommand(
        cmd.program,
        cmd.timeout,
        relativeToBase = true,
        outputPath.some,
        cachePath.some
      )
      .withArgs(_.append(cmd.args))
      .addEnv(cmd.env)

    val chroot = ctx.baseDir / "cnt-root"
    val nspawn = NSpawnBuilder(addonCmd, chroot)
      .withNSpawnBinary(cfg.nspawnBinary)
      .withSudoBinary(cfg.sudoBinary)
      .mount(ctx.baseDir, "/mnt/work".some, readOnly = false)
      .mount(ctx.cacheDir, cachePath.some, readOnly = false)
      .mount(ctx.outputDir, outputPath.some, readOnly = false)
      .workDirectory("/mnt/work")
      .withEnv("XDG_RUNTIME_DIR", "/mnt/work")
      .privateNetwork(ctx.meta.isPure)

    for {
      suffix <- Random[F].string(4)
      _ <- List(chroot).traverse_(Files[F].createDirectories)
      res <- runAddonCommand(
        logger,
        nspawn.withName(ctx.meta.nameAndVersion + "-" + suffix).build,
        ctx
      )
      // allow some time to unregister the current container
      // only important when same addons are called in sequence too fast
      _ <- Sync[F].sleep(cfg.containerWait.toScala)
    } yield res
  }

  private def procPipe[F[_]](
      p: String,
      ctx: Context,
      collect: CollectOut[F],
      logger: Logger[F]
  ): Pipe[F, String, Unit] =
    _.through(collect.append)
      .map(line => s">> [${ctx.meta.nameAndVersion} ($p)] $line")
      .evalMap(logger.debug(_))

  /** Runs the external command that is executing the addon.
    *
    * If the addons specifies to collect its output, the stdout is parsed as json and
    * decoded into [[AddonOutput]].
    */
  def runAddonCommand[F[_]: Async](
      logger: Logger[F],
      cmd: SysCmd,
      ctx: Context
  ): F[AddonResult] =
    for {
      stdout <-
        if (ctx.meta.parseResult) CollectOut.buffer[F]
        else CollectOut.none[F].pure[F]
      cmdResult <- SysExec(cmd, logger, ctx.baseDir.some)
        .flatMap(
          _.consumeOutputs(
            procPipe("out", ctx, stdout, logger),
            procPipe("err", ctx, CollectOut.none[F], logger)
          )
        )
        .use(_.waitFor())
        .attempt
      addonResult <- cmdResult match {
        case Right(rc) if rc != 0 =>
          for {
            _ <- logger.error(
              s"Addon ${ctx.meta.nameAndVersion} returned non-zero: $rc"
            )
          } yield AddonResult.executionError(rc)

        case Right(_) =>
          for {
            _ <- logger.debug(s"Addon ${ctx.meta.nameAndVersion} executed successfully!")
            out <- stdout.get
            _ <- logger.debug(s"Addon stdout: $out")
            result = Option
              .when(ctx.meta.parseResult && out.nonEmpty)(
                JsonParser
                  .decode[AddonOutput](out)
                  .fold(AddonResult.decodingError, AddonResult.success)
              )
              .getOrElse(AddonResult.empty)
          } yield result

        case Left(ex) =>
          logger
            .error(ex)(s"Executing external command failed!")
            .as(AddonResult.executionFailed(ex))
      }
    } yield addonResult

  /** Check whether `systemd-nspawn` is available on this machine. */
  def checkContainer[F[_]: Async](
      logger: Logger[F],
      cfg: AddonExecutorConfig.NSpawn
  ): F[Boolean] =
    for {
      rc <- SysExec(cfg.nspawnVersion, logger)
        .flatMap(_.logOutputs(logger, "nspawn"))
        .use(_.waitFor())
      _ <-
        OptionT
          .whenF(rc != 0)(
            logger.warn(
              s"No systemd-nspawn found! Addon is not executed inside a container."
            )
          )
          .value
    } yield rc == 0
}
