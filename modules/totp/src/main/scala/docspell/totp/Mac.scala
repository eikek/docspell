/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import cats.data.NonEmptyList

import com.eatthepath.otp.TimeBasedOneTimePasswordGenerator
import io.circe.{Decoder, Encoder}

sealed trait Mac {
  def identifier: String
  def keyLengthBits: Int
}
object Mac {
  case object Sha1 extends Mac {
    val identifier    = TimeBasedOneTimePasswordGenerator.TOTP_ALGORITHM_HMAC_SHA1
    val keyLengthBits = 160
  }
  case object Sha256 extends Mac {
    val identifier    = TimeBasedOneTimePasswordGenerator.TOTP_ALGORITHM_HMAC_SHA256
    val keyLengthBits = 256
  }
  case object Sha512 extends Mac {
    val identifier    = TimeBasedOneTimePasswordGenerator.TOTP_ALGORITHM_HMAC_SHA512
    val keyLengthBits = 512
  }

  val all: NonEmptyList[Mac] =
    NonEmptyList.of(Sha1, Sha256, Sha512)

  def fromString(str: String): Either[String, Mac] =
    str.toLowerCase match {
      case "hmacsha1"   => Right(Sha1)
      case "hmacsha256" => Right(Sha256)
      case "hmacsha512" => Right(Sha512)
      case _            => Left(s"Unknown mac name: $str")
    }

  def unsafeFromString(str: String): Mac =
    fromString(str).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[Mac] =
    Encoder.encodeString.contramap(_.identifier)

  implicit val jsonDecoder: Decoder[Mac] =
    Decoder.decodeString.emap(fromString)
}
