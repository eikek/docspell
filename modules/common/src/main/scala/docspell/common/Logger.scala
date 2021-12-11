/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.io.{PrintWriter, StringWriter}

import cats.Applicative
import cats.effect.{Ref, Sync}
import cats.implicits._
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
  def andThen(other: Logger[F])(implicit F: Sync[F]): Logger[F] = {
    val self = this
    new Logger[F] {
      def trace(msg: => String) =
        self.trace(msg) >> other.trace(msg)

      override def debug(msg: => String) =
        self.debug(msg) >> other.debug(msg)

      override def info(msg: => String) =
        self.info(msg) >> other.info(msg)

      override def warn(msg: => String) =
        self.warn(msg) >> other.warn(msg)

      override def error(ex: Throwable)(msg: => String) =
        self.error(ex)(msg) >> other.error(ex)(msg)

      override def error(msg: => String) =
        self.error(msg) >> other.error(msg)
    }
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

  def buffer[F[_]: Sync](): F[(Ref[F, Vector[String]], Logger[F])] =
    for {
      buffer <- Ref.of[F, Vector[String]](Vector.empty[String])
      logger = new Logger[F] {
        def trace(msg: => String) =
          buffer.update(_.appended(s"TRACE $msg"))

        def debug(msg: => String) =
          buffer.update(_.appended(s"DEBUG $msg"))

        def info(msg: => String) =
          buffer.update(_.appended(s"INFO $msg"))

        def warn(msg: => String) =
          buffer.update(_.appended(s"WARN $msg"))

        def error(ex: Throwable)(msg: => String) = {
          val ps = new StringWriter()
          ex.printStackTrace(new PrintWriter(ps))
          buffer.update(_.appended(s"ERROR $msg:\n$ps"))
        }

        def error(msg: => String) =
          buffer.update(_.appended(s"ERROR $msg"))
      }
    } yield (buffer, logger)

}
