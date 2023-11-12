/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import cats.effect._
import cats.syntax.all._
import fs2._
import fs2.concurrent.{Signal, SignallingRef}

object ResourceUse {
  def apply[F[_]: Concurrent, A](
      resource: Resource[F, A]
  ): Implicits.UseSyntax[F, A] =
    new Implicits.UseSyntax(resource)

  object Implicits {
    implicit final class UseSyntax[F[_]: Concurrent, A](resource: Resource[F, A]) {

      def useWhile(
          signal: Signal[F, Boolean],
          returnValue: Ref[F, ExitCode]
      ): Stream[F, ExitCode] = {
        val server = Stream.resource(resource)
        val blockUntilTrue = signal.discrete.takeWhile(_ == false).drain
        val exit = Stream.eval(returnValue.get)
        server *> (blockUntilTrue ++ exit)
      }

      def useForever(implicit ev: Async[F]): Stream[F, ExitCode] = for {
        termSignal <- Stream.eval(SignallingRef.of[F, Boolean](false))
        exitValue <- Stream.eval(Ref.of(ExitCode.Success))
        rc <- useWhile(termSignal, exitValue)
      } yield rc
    }
  }
}
