/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait PassLength {
  def toInt: Int
}

object PassLength {
  case object Chars6 extends PassLength {
    val toInt = 6
  }
  case object Chars8 extends PassLength {
    val toInt = 8
  }

  val all: NonEmptyList[PassLength] =
    NonEmptyList.of(Chars6, Chars8)

  def fromInt(n: Int): Either[String, PassLength] =
    n match {
      case 6 => Right(Chars6)
      case 8 => Right(Chars8)
      case _ => Left(s"Invalid length: $n! Must be either 6 or 8")
    }

  def unsafeFromInt(n: Int): PassLength =
    fromInt(n).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[PassLength] =
    Encoder.encodeInt.contramap(_.toInt)

  implicit val jsonDecoder: Decoder[PassLength] =
    Decoder.decodeInt.emap(fromInt)
}
