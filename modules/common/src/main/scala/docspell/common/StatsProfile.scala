/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait StatsProfile { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object StatsProfile {

  final case object Full extends StatsProfile
  final case object General extends StatsProfile
  final case object Fields extends StatsProfile

  val default: StatsProfile = Full

  def fromString(str: String): Either[String, StatsProfile] =
    str.toLowerCase match {
      case "full"    => Right(Full)
      case "general" => Right(General)
      case "fields"  => Right(Fields)
      case _         => Left(s"Invalid stats profile: $str")
    }

  val all: NonEmptyList[StatsProfile] =
    NonEmptyList.of(Full, General, Fields)

  def unsafe(str: String): StatsProfile =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[StatsProfile] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[StatsProfile] =
    Encoder.encodeString.contramap(_.name)
}
