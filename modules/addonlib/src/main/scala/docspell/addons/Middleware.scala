/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.Monad
import cats.data.Kleisli
import cats.effect.kernel.Sync
import cats.syntax.all._
import fs2.io.file.Files

trait Middleware[F[_]] extends (AddonExec[F] => AddonExec[F]) { self =>

  def >>(next: Middleware[F]): Middleware[F] =
    Middleware(self.andThen(next))
}

object Middleware {
  def apply[F[_]](f: AddonExec[F] => AddonExec[F]): Middleware[F] =
    a => f(a)

  def identity[F[_]]: Middleware[F] = Middleware(scala.Predef.identity)

  /** Uses a temporary base dir that is removed after execution. Use this as the last
    * layer!
    */
  def ephemeralRun[F[_]: Files: Sync]: Middleware[F] =
    Middleware(a => Kleisli(_.withTempBase.use(a.run)))

  /** Prepare running an addon */
  def prepare[F[_]: Monad](
      prep: Kleisli[F, InputEnv, InputEnv]
  ): Middleware[F] =
    Middleware(a => Kleisli(in => prep.run(in).flatMap(a.run)))

  def postProcess[F[_]: Monad](
      post: Kleisli[F, AddonExecutionResult, Unit]
  ): Middleware[F] =
    Middleware(_.flatMapF(r => post.map(_ => r).run(r)))
}
