/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.data.Kleisli
import cats.effect._
import cats.syntax.all._
import fs2.Stream
import fs2.io.file._

import docspell.common.UrlReader
import docspell.common.exec.Env
import docspell.common.util.Directory
import docspell.logging.Logger

trait AddonExecutor[F[_]] {

  def config: AddonExecutorConfig

  def execute(logger: Logger[F]): AddonExec[F]

  def execute(logger: Logger[F], in: InputEnv): F[AddonExecutionResult] =
    execute(logger).run(in)
}

object AddonExecutor {

  def apply[F[_]: Async](
      cfg: AddonExecutorConfig,
      urlReader: UrlReader[F]
  ): AddonExecutor[F] =
    new AddonExecutor[F] with AddonLoggerExtension {
      val config = cfg

      def execute(logger: Logger[F]): AddonExec[F] =
        Kleisli { in =>
          for {
            _ <- logger.info(s"About to run ${in.addons.size} addon(s) in ${in.baseDir}")
            ctx <- prepareDirectory(
              logger,
              in.baseDir,
              in.outputDir,
              in.cacheDir,
              in.addons
            )
            rs <-
              if (cfg.failFast) ctx.foldLeftM(List.empty[AddonResult]) { (res, c) =>
                if (res.headOption.exists(_.isFailure)) res.pure[F]
                else runAddon(logger.withAddon(c), in.env)(c).map(r => r :: res)
              }
              else ctx.traverse(c => runAddon(logger.withAddon(c), in.env)(c))
            pure = ctx.foldl(true)((b, c) => b && c.meta.isPure)
          } yield AddonExecutionResult(rs, pure)
        }

      private def prepareDirectory(
          logger: Logger[F],
          baseDir: Path,
          outDir: Path,
          cacheDir: Path,
          addons: List[AddonRef]
      ): F[List[Context]] =
        for {
          addonsDir <- Directory.create(baseDir / "addons")
          _ <- Directory.createAll(Context.tempDir(baseDir), outDir, cacheDir)
          _ <- Context
            .userInputFile(baseDir)
            .parent
            .fold(().pure[F])(Files[F].createDirectories)
          archives = addons.map(_.archive).distinctBy(_.url)
          _ <- logger.info(s"Extract ${archives.size} addons to $addonsDir")
          mkCtxs <- archives.traverse { archive =>
            for {
              _ <- logger.debug(s"Extracting $archive")
              addonDir <- archive.extractTo(urlReader, addonsDir)
              meta <- AddonMeta.findInDirectory(addonDir)
              mkCtx = (ref: AddonRef) =>
                Context(ref, meta, baseDir, addonDir, outDir, cacheDir)
            } yield archive.url -> mkCtx
          }
          ctxFactory = mkCtxs.toMap
          res = addons.map(ref => ctxFactory(ref.archive.url)(ref))
        } yield res

      private def runAddon(logger: Logger[F], env: Env)(
          ctx: Context
      ): F[AddonResult] =
        for {
          _ <- logger.info(s"Executing addon ${ctx.meta.nameAndVersion}")
          _ <- logger.trace("Storing user input into file")
          _ <- Stream
            .emit(ctx.addon.args)
            .through(fs2.text.utf8.encode)
            .through(Files[F].writeAll(ctx.userInputFile, Flags.Write))
            .compile
            .drain

          runner <- selectRunner(cfg, ctx.meta, ctx.addonDir)
          result <- runner.run(logger, env, ctx)
        } yield result
    }

  def selectRunner[F[_]: Async](
      cfg: AddonExecutorConfig,
      meta: AddonMeta,
      addonDir: Path
  ): F[AddonRunner[F]] =
    for {
      addonRunner <- meta.enabledTypes(Left(addonDir))
      // intersect on list retains order in first
      possibleRunner = cfg.runner
        .intersect(addonRunner)
        .map(AddonRunner.forType[F](cfg))
      runner = possibleRunner match {
        case Nil =>
          AddonRunner.failWith(
            s"No runner available for addon config ${meta.runner} and config ${cfg.runner}."
          )
        case list =>
          AddonRunner.firstSuccessful(list)
      }
    } yield runner
}
