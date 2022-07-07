/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import cats.Id
import cats.effect.Sync

import docspell.logging.{Level, LogEvent, Logger}

import scribe.LoggerSupport
import scribe.data.{MDC, MDCMap}
import scribe.message.LoggableMessage

private[logging] object ScribeWrapper {
  final class ImplUnsafe(log: scribe.Logger) extends Logger[Id] {
    override def asUnsafe = this

    override def log(ev: => LogEvent): Unit =
      log.log(convert(ev))
  }
  final class Impl[F[_]: Sync](log: scribe.Logger) extends Logger[F] {
    override def asUnsafe = new ImplUnsafe(log)

    override def log(ev: => LogEvent) =
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

  private[this] def emptyMDC: MDC =
    new MDCMap(None)

  private[this] def convert(ev: LogEvent) = {
    val level = convertLevel(ev.level)
    val additional: List[LoggableMessage] = ev.additional.map {
      case Right(ex) => LoggableMessage.throwable2Message(ex)
      case Left(msg) => LoggableMessage.string2Message(msg)
    }.toList
    LoggerSupport(
      level,
      ev.msg() :: additional,
      ev.pkg,
      ev.fileName,
      ev.name,
      ev.line,
      emptyMDC
    )
      .copy(data = ev.data.toDeferred)
  }
}
