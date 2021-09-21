/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait ContactKind { self: Product =>

  def asString: String = self.productPrefix
}

object ContactKind {
  val all = List()

  case object Phone   extends ContactKind
  case object Mobile  extends ContactKind
  case object Fax     extends ContactKind
  case object Email   extends ContactKind
  case object Website extends ContactKind

  def fromString(s: String): Either[String, ContactKind] =
    s.toLowerCase match {
      case "phone"   => Right(Phone)
      case "mobile"  => Right(Mobile)
      case "fax"     => Right(Fax)
      case "email"   => Right(Email)
      case "website" => Right(Website)
      case _         => Left(s"Not a state value: $s")
    }

  def unsafe(str: String): ContactKind =
    fromString(str).fold(sys.error, identity)

  def asString(s: ContactKind): String =
    s.asString.toLowerCase

  implicit val contactKindEncoder: Encoder[ContactKind] =
    Encoder.encodeString.contramap(_.asString)

  implicit val contactKindDecoder: Decoder[ContactKind] =
    Decoder.decodeString.emap(ContactKind.fromString)

}
