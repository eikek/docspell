/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.Applicative
import cats.effect._
import cats.syntax.all._
import fs2.Stream

import docspell.addons.runner._
import docspell.common.exec.Env
import docspell.logging.Logger

trait AddonRunner[F[_]] {
  def runnerType: List[RunnerType]

  def run(
      logger: Logger[F],
      env: Env,
      ctx: Context
  ): F[AddonResult]
}

object AddonRunner {
  def forType[F[_]: Async](cfg: AddonExecutorConfig)(rt: RunnerType) =
    rt match {
      case RunnerType.NixFlake => NixFlakeRunner[F](cfg)
      case RunnerType.Docker   => DockerRunner[F](cfg)
      case RunnerType.Trivial  => TrivialRunner[F](cfg)
    }

  def failWith[F[_]](errorMsg: String)(implicit F: Applicative[F]): AddonRunner[F] =
    pure(AddonResult.executionFailed(new Exception(errorMsg)))

  def pure[F[_]: Applicative](result: AddonResult): AddonRunner[F] =
    new AddonRunner[F] {
      val runnerType = Nil

      def run(logger: Logger[F], env: Env, ctx: Context) =
        Applicative[F].pure(result)
    }

  def firstSuccessful[F[_]: Sync](runners: List[AddonRunner[F]]): AddonRunner[F] =
    runners match {
      case Nil      => failWith("No runner available!")
      case a :: Nil => a
      case _ =>
        new AddonRunner[F] {
          val runnerType = runners.flatMap(_.runnerType).distinct

          def run(logger: Logger[F], env: Env, ctx: Context) =
            Stream
              .emits(runners)
              .evalTap(r =>
                logger.info(
                  s"Attempt to run addon ${ctx.meta.nameAndVersion} with runner ${r.runnerType}"
                )
              )
              .evalMap(_.run(logger, env, ctx))
              .flatMap {
                case r @ AddonResult.Success(_) => Stream.emit(r.cast.some)
                case r @ AddonResult.ExecutionFailed(ex) =>
                  if (ctx.meta.isPure) {
                    logger.stream
                      .warn(ex)(s"Addon runner failed, try next.")
                      .as(r.cast.some)
                  } else {
                    logger.stream.warn(ex)(s"Addon runner failed!").as(None)
                  }
                case r @ AddonResult.ExecutionError(rc) =>
                  if (ctx.meta.isPure) {
                    logger.stream
                      .warn(s"Addon runner returned non-zero: $rc. Try next.")
                      .as(r.cast.some)
                  } else {
                    logger.stream.warn(s"Addon runner returned non-zero: $rc!").as(None)
                  }
                case AddonResult.DecodingError(message) =>
                  // Don't retry as it is very unlikely that the output differs using another runner
                  // This is most likely a bug in the addon
                  logger.stream
                    .warn(
                      s"Error decoding the output of the addon ${ctx.meta.nameAndVersion}: $message. Stopping here. This is likely a bug in the addon."
                    )
                    .as(None)
              }
              .unNoneTerminate
              .takeThrough(_.isFailure)
              .compile
              .last
              .flatMap {
                case Some(r) => r.pure[F]
                case None =>
                  AddonResult
                    .executionFailed(new NoSuchElementException("No runner left :("))
                    .pure[F]
              }
        }
    }

  def firstSuccessful[F[_]: Sync](
      runner: AddonRunner[F],
      runners: AddonRunner[F]*
  ): AddonRunner[F] =
    firstSuccessful(runner :: runners.toList)
}
