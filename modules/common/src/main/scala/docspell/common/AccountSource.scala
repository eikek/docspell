/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait AccountSource { self: Product =>

  def name: String =
    self.productPrefix.toLowerCase
}

object AccountSource {

  case object Local extends AccountSource
  case object OpenId extends AccountSource

  val all: NonEmptyList[AccountSource] =
    NonEmptyList.of(Local, OpenId)

  def fromString(str: String): Either[String, AccountSource] =
    str.toLowerCase match {
      case "local"  => Right(Local)
      case "openid" => Right(OpenId)
      case _        => Left(s"Invalid account source: $str")
    }

  def unsafeFromString(str: String): AccountSource =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[AccountSource] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[AccountSource] =
    Encoder.encodeString.contramap(_.name)
}
