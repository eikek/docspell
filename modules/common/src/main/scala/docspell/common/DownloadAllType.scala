/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait DownloadAllType {
  def name: String
}

object DownloadAllType {

  case object Converted extends DownloadAllType { val name = "converted" }
  case object Original extends DownloadAllType { val name = "original" }

  val all: NonEmptyList[DownloadAllType] =
    NonEmptyList.of(Converted, Original)

  def fromString(str: String): Either[String, DownloadAllType] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Unknown type: $str")

  def unsafeFromString(str: String): DownloadAllType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[DownloadAllType] =
    Encoder.encodeString.contramap(_.name)

  implicit val jsonDecoder: Decoder[DownloadAllType] =
    Decoder.decodeString.emap(fromString)
}
