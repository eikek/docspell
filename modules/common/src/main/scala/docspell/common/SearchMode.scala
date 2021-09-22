/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.Decoder
import io.circe.Encoder

sealed trait SearchMode { self: Product =>

  final def name: String =
    productPrefix.toLowerCase

}

object SearchMode {

  final case object Normal extends SearchMode
  final case object Trashed extends SearchMode
  final case object All extends SearchMode

  def fromString(str: String): Either[String, SearchMode] =
    str.toLowerCase match {
      case "normal"  => Right(Normal)
      case "trashed" => Right(Trashed)
      case "all"     => Right(All)
      case _         => Left(s"Invalid search mode: $str")
    }

  val all: NonEmptyList[SearchMode] =
    NonEmptyList.of(Normal, Trashed)

  def unsafe(str: String): SearchMode =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[SearchMode] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[SearchMode] =
    Encoder.encodeString.contramap(_.name)
}
