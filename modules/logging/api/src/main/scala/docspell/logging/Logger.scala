/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import java.io.PrintStream
import java.time.Instant

import cats.effect.{Ref, Sync}
import cats.syntax.applicative._
import cats.syntax.functor._
import cats.syntax.order._
import cats.{Applicative, Functor, Id}

import io.circe.{Encoder, Json}
import sourcecode._

trait Logger[F[_]] extends LoggerExtension[F] {

  def log(ev: => LogEvent): F[Unit]

  def asUnsafe: Logger[Id]

  def captureAll(data: LazyMap[String, Json]): Logger[F] =
    CapturedLogger(this, data)

  def captureAll(data: Map[String, Json]): Logger[F] =
    CapturedLogger(this, LazyMap.fromMap(data))

  def capture[A: Encoder](key: String, value: => A): Logger[F] = {
    val enc = Encoder[A]
    CapturedLogger(this, LazyMap.empty[String, Json].updated(key, enc(value)))
  }

  def trace(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Trace, msg))

  def traceWith(msg: => String)(modify: LogEvent => LogEvent)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(modify(LogEvent.of(Level.Trace, msg)))

  def debug(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Debug, msg))

  def debugWith(msg: => String)(modify: LogEvent => LogEvent)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(modify(LogEvent.of(Level.Debug, msg)))

  def info(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Info, msg))

  def infoWith(msg: => String)(modify: LogEvent => LogEvent)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(modify(LogEvent.of(Level.Info, msg)))

  def warn(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Warn, msg))

  def warnWith(msg: => String)(modify: LogEvent => LogEvent)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(modify(LogEvent.of(Level.Warn, msg)))

  def warn(ex: Throwable)(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Warn, msg).addError(ex))

  def error(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Error, msg))

  def errorWith(msg: => String)(modify: LogEvent => LogEvent)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(modify(LogEvent.of(Level.Error, msg)))

  def error(ex: Throwable)(msg: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): F[Unit] =
    log(LogEvent.of(Level.Error, msg).addError(ex))
}

object Logger {
  def off: Logger[Id] =
    new Logger[Id] {
      def log(ev: => LogEvent): Unit = ()
      def asUnsafe = this
    }

  def offF[F[_]: Applicative]: Logger[F] =
    new Logger[F] {
      def log(ev: => LogEvent) = ().pure[F]
      def asUnsafe = off
    }

  def buffer[F[_]: Ref.Make: Functor](): F[(Ref[F, Vector[LogEvent]], Logger[F])] =
    for {
      buffer <- Ref.of[F, Vector[LogEvent]](Vector.empty[LogEvent])
      logger =
        new Logger[F] {
          def log(ev: => LogEvent) =
            buffer.update(_.appended(ev))
          def asUnsafe = off
        }
    } yield (buffer, logger)

  /** Just prints to the given print stream. Useful for testing. */
  def simple(ps: PrintStream, minimumLevel: Level): Logger[Id] =
    new Logger[Id] {
      def log(ev: => LogEvent): Unit =
        if (ev.level >= minimumLevel)
          ps.println(s"${Instant.now()} [${Thread.currentThread()}] ${ev.asString}")
        else
          ()

      def asUnsafe = this
    }

  def simpleF[F[_]: Sync](ps: PrintStream, minimumLevel: Level): Logger[F] =
    new Logger[F] {
      def log(ev: => LogEvent) =
        Sync[F].delay(asUnsafe.log(ev))

      val asUnsafe = simple(ps, minimumLevel)
    }

  def simpleDefault[F[_]: Sync](minimumLevel: Level = Level.Info): Logger[F] =
    simpleF[F](System.err, minimumLevel)
}
