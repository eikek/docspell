/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

final case class LogConfig(
    minimumLevel: Level,
    format: LogConfig.Format,
    levels: LogConfig.ExtraLevels
) {

  def clearLevels: LogConfig =
    copy(levels = Map.empty)

  def withLevel(logger: String, level: Level): LogConfig =
    copy(levels = levels.updated(logger, level))

  def docspellLevel(level: Level): LogConfig =
    withLevel("docspell", level)
}

object LogConfig {

  type ExtraLevels = Map[String, Level]

  sealed trait Format { self: Product =>
    def name: String =
      productPrefix.toLowerCase
  }
  object Format {
    case object Plain extends Format
    case object Fancy extends Format
    case object Json extends Format
    case object Logfmt extends Format

    val all: NonEmptyList[Format] =
      NonEmptyList.of(Plain, Fancy, Json, Logfmt)

    def fromString(str: String): Either[String, Format] =
      all.find(_.name.equalsIgnoreCase(str)).toRight(s"Invalid format name: $str")

    implicit val jsonDecoder: Decoder[Format] =
      Decoder.decodeString.emap(fromString)

    implicit val jsonEncoder: Encoder[Format] =
      Encoder.encodeString.contramap(_.name)
  }

  implicit val jsonDecoder: Decoder[LogConfig] =
    Decoder.forProduct3("minimumLevel", "format", "levels")(LogConfig.apply)

  implicit val jsonEncoder: Encoder[LogConfig] =
    Encoder.forProduct3("minimumLevel", "format", "levels")(r =>
      (r.minimumLevel, r.format, r.levels)
    )
}
