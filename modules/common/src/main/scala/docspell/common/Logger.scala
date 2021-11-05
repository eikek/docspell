/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.Applicative
import cats.effect.Sync
import fs2.Stream

import docspell.common.syntax.all._

import org.log4s.{Logger => Log4sLogger}

trait Logger[F[_]] { self =>

  def trace(msg: => String): F[Unit]
  def debug(msg: => String): F[Unit]
  def info(msg: => String): F[Unit]
  def warn(msg: => String): F[Unit]
  def error(ex: Throwable)(msg: => String): F[Unit]
  def error(msg: => String): F[Unit]

  final def s: Logger[Stream[F, *]] = new Logger[Stream[F, *]] {
    def trace(msg: => String): Stream[F, Unit] =
      Stream.eval(self.trace(msg))

    def debug(msg: => String): Stream[F, Unit] =
      Stream.eval(self.debug(msg))

    def info(msg: => String): Stream[F, Unit] =
      Stream.eval(self.info(msg))

    def warn(msg: => String): Stream[F, Unit] =
      Stream.eval(self.warn(msg))

    def error(msg: => String): Stream[F, Unit] =
      Stream.eval(self.error(msg))

    def error(ex: Throwable)(msg: => String): Stream[F, Unit] =
      Stream.eval(self.error(ex)(msg))
  }
}

object Logger {

  def off[F[_]: Applicative]: Logger[F] =
    new Logger[F] {
      def trace(msg: => String): F[Unit] =
        Applicative[F].pure(())

      def debug(msg: => String): F[Unit] =
        Applicative[F].pure(())

      def info(msg: => String): F[Unit] =
        Applicative[F].pure(())

      def warn(msg: => String): F[Unit] =
        Applicative[F].pure(())

      def error(ex: Throwable)(msg: => String): F[Unit] =
        Applicative[F].pure(())

      def error(msg: => String): F[Unit] =
        Applicative[F].pure(())
    }

  def log4s[F[_]: Sync](log: Log4sLogger): Logger[F] =
    new Logger[F] {
      def trace(msg: => String): F[Unit] =
        log.ftrace(msg)

      def debug(msg: => String): F[Unit] =
        log.fdebug(msg)

      def info(msg: => String): F[Unit] =
        log.finfo(msg)

      def warn(msg: => String): F[Unit] =
        log.fwarn(msg)

      def error(ex: Throwable)(msg: => String): F[Unit] =
        log.ferror(ex)(msg)

      def error(msg: => String): F[Unit] =
        log.ferror(msg)
    }

}
