/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.syntax

trait EitherSyntax {

  implicit final class LeftStringEitherOps[A](e: Either[String, A]) {
    def throwLeft: A =
      e.fold(sys.error, identity)
  }

  implicit final class ThrowableLeftEitherOps[A](e: Either[Throwable, A]) {
    def throwLeft: A =
      e match {
        case Right(a)  => a
        case Left(err) => throw err
      }
  }

}

object EitherSyntax extends EitherSyntax
