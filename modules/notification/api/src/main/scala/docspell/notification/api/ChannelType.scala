/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Order
import cats.data.{NonEmptyList => Nel}

import io.circe.Decoder
import io.circe.Encoder

sealed trait ChannelType { self: Product =>

  def name: String =
    productPrefix
}

object ChannelType {

  case object Mail extends ChannelType
  case object Gotify extends ChannelType
  case object Matrix extends ChannelType
  case object Http extends ChannelType

  val all: Nel[ChannelType] =
    Nel.of(Mail, Gotify, Matrix, Http)

  def fromString(str: String): Either[String, ChannelType] =
    str.toLowerCase match {
      case "mail"   => Right(Mail)
      case "gotify" => Right(Gotify)
      case "matrix" => Right(Matrix)
      case "http"   => Right(Http)
      case _        => Left(s"Unknown channel type: $str")
    }

  def unsafeFromString(str: String): ChannelType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[ChannelType] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[ChannelType] =
    Encoder.encodeString.contramap(_.name)

  implicit val order: Order[ChannelType] =
    Order.by(_.name)
}
