/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.data.NonEmptyList
import cats.syntax.all._
import cats.{Applicative, Id}

final private[logging] class AndThenLogger[F[_]: Applicative](
    val loggers: NonEmptyList[Logger[F]]
) extends Logger[F] {
  def log(ev: => LogEvent): F[Unit] =
    loggers.traverse(_.log(ev)).as(())

  def asUnsafe: Logger[Id] =
    new Logger[Id] { self =>
      def log(ev: => LogEvent): Unit =
        loggers.toList.foreach(_.asUnsafe.log(ev))
      def asUnsafe = self
    }
}

private[logging] object AndThenLogger {
  def combine[F[_]: Applicative](a: Logger[F], b: Logger[F]): Logger[F] =
    (a, b) match {
      case (aa: AndThenLogger[F], bb: AndThenLogger[F]) =>
        new AndThenLogger[F](aa.loggers ++ bb.loggers.toList)
      case (aa: AndThenLogger[F], _) =>
        new AndThenLogger[F](aa.loggers.prepend(b))
      case (_, bb: AndThenLogger[F]) =>
        new AndThenLogger[F](bb.loggers.prepend(a))
      case _ =>
        new AndThenLogger[F](NonEmptyList.of(a, b))
    }
}
