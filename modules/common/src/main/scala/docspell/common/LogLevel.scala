/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import docspell.logging.Level

import io.circe.{Decoder, Encoder}

sealed trait LogLevel { self: Product =>
  def toInt: Int
  final def name: String =
    productPrefix.toLowerCase
}

object LogLevel {

  case object Debug extends LogLevel { val toInt = 0 }
  case object Info extends LogLevel { val toInt = 1 }
  case object Warn extends LogLevel { val toInt = 2 }
  case object Error extends LogLevel { val toInt = 3 }

  def fromInt(n: Int): LogLevel =
    n match {
      case 0 => Debug
      case 1 => Info
      case 2 => Warn
      case 3 => Error
      case _ => Debug
    }

  def fromString(str: String): Either[String, LogLevel] =
    str.toLowerCase match {
      case "debug"   => Right(Debug)
      case "info"    => Right(Info)
      case "warn"    => Right(Warn)
      case "warning" => Right(Warn)
      case "error"   => Right(Error)
      case _         => Left(s"Invalid log-level: $str")
    }

  def fromLevel(level: Level): LogLevel =
    level match {
      case Level.Fatal => LogLevel.Error
      case Level.Error => LogLevel.Error
      case Level.Warn  => LogLevel.Warn
      case Level.Info  => LogLevel.Info
      case Level.Debug => LogLevel.Debug
      case Level.Trace => LogLevel.Debug
    }

  def unsafeString(str: String): LogLevel =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[LogLevel] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[LogLevel] =
    Encoder.encodeString.contramap(_.name)
}
