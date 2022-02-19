/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.Id
import cats.effect.Sync

import docspell.logging.impl.LoggerWrapper

import sourcecode._

trait Logger[F[_]] {

  def log(ev: LogEvent): F[Unit]

  def asUnsafe: Logger[Id]

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
  def unsafe(name: String): Logger[Id] =
    new LoggerWrapper.ImplUnsafe(scribe.Logger(name))

  def apply[F[_]: Sync](name: String): Logger[F] =
    new LoggerWrapper.Impl[F](scribe.Logger(name))

  def apply[F[_]: Sync](clazz: Class[_]): Logger[F] =
    new LoggerWrapper.Impl[F](scribe.Logger(clazz.getName))
}
