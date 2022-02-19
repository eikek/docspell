/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import cats.Id
import cats.effect._

import docspell.logging._

import scribe.LoggerSupport
import scribe.message.{LoggableMessage, Message}

private[logging] object LoggerWrapper {
  final class ImplUnsafe(log: scribe.Logger) extends Logger[Id] {
    override def asUnsafe = this

    override def log(ev: LogEvent): Unit =
      log.log(convert(ev))
  }
  final class Impl[F[_]: Sync](log: scribe.Logger) extends Logger[F] {
    override def asUnsafe = new ImplUnsafe(log)

    override def log(ev: LogEvent) =
      Sync[F].delay(log.log(convert(ev)))
  }

  private[impl] def convertLevel(l: Level): scribe.Level =
    l match {
      case Level.Fatal => scribe.Level.Fatal
      case Level.Error => scribe.Level.Error
      case Level.Warn  => scribe.Level.Warn
      case Level.Info  => scribe.Level.Info
      case Level.Debug => scribe.Level.Debug
      case Level.Trace => scribe.Level.Trace
    }

  private[this] def convert(ev: LogEvent) = {
    val level = convertLevel(ev.level)
    val additional: List[LoggableMessage] = ev.additional.map { x =>
      x() match {
        case Right(ex) => Message.static(ex)
        case Left(msg) => Message.static(msg)
      }
    }
    LoggerSupport(level, ev.msg(), additional, ev.pkg, ev.fileName, ev.name, ev.line)
      .copy(data = ev.data)
  }
}
