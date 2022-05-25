/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._

import docspell.addons.AddonExecutorConfig.DockerConfig
import docspell.addons._
import docspell.common.Duration
import docspell.common.exec.{Env, SysCmd, SysExec}
import docspell.common.util.Random
import docspell.logging.Logger

final class DockerRunner[F[_]: Async](cfg: DockerRunner.Config) extends AddonRunner[F] {

  val runnerType = List(RunnerType.Docker)

  def run(
      logger: Logger[F],
      env: Env,
      ctx: Context
  ) = for {
    _ <- OptionT.whenF(requireBuild(ctx))(build(logger, ctx)).value
    suffix <- Random[F].string(4)
    cmd = createDockerCommand(env, ctx, suffix)
    result <- RunnerUtil.runAddonCommand(logger, cmd, ctx)
  } yield result

  def createDockerCommand(
      env: Env,
      ctx: Context,
      suffix: String
  ): SysCmd = {
    val outputPath = "/mnt/output"
    val cachePath = "/mnt/cache"
    val addonArgs =
      ctx.addonCommand(
        "",
        Duration.zero,
        relativeToBase = true,
        outputPath.some,
        cachePath.some
      )

    DockerBuilder(cfg.docker.dockerBinary, "run", cfg.timeout)
      .withName(ctx.meta.nameAndVersion + "-" + suffix)
      .withEnv(env)
      .withEnv(addonArgs.env)
      .mount(ctx.baseDir, "/mnt/work".some, readOnly = false)
      .mount(ctx.outputDir, outputPath.some, readOnly = false)
      .mount(ctx.cacheDir, cachePath.some, readOnly = false)
      .workDirectory("/mnt/work")
      .privateNetwork(ctx.meta.isPure)
      .imageName(imageName(ctx))
      .containerCmd(addonArgs.args)
      .build
  }

  def build(logger: Logger[F], ctx: Context): F[Unit] =
    for {
      _ <- logger.info(s"Building docker image for addon ${ctx.meta.nameAndVersion}")
      cmd = cfg.docker.dockerBuild(imageName(ctx))
      _ <- SysExec(cmd, logger, ctx.addonDir.some)
        .flatMap(_.logOutputs(logger, "docker build"))
        .use(_.waitFor())
      _ <- logger.info(s"Docker image built successfully")
    } yield ()

  private def requireBuild(ctx: Context) =
    ctx.meta.runner
      .flatMap(_.docker)
      .flatMap(_.image)
      .isEmpty

  private def imageName(ctx: Context): String =
    ctx.meta.runner
      .flatMap(_.docker)
      .flatMap(_.image)
      .getOrElse(s"${ctx.meta.meta.name}:latest")
}

object DockerRunner {
  def apply[F[_]: Async](cfg: AddonExecutorConfig): DockerRunner[F] =
    new DockerRunner[F](Config(cfg.dockerRunner, cfg.runTimeout))

  case class Config(docker: DockerConfig, timeout: Duration)
}
