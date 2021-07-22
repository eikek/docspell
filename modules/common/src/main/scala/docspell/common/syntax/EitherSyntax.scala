/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common.syntax

trait EitherSyntax {

  implicit final class LeftStringEitherOps[A](e: Either[String, A]) {
    def throwLeft: A =
      e match {
        case Right(a)  => a
        case Left(err) => sys.error(err)
      }
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
