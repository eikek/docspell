/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.Decoder
import io.circe.Encoder

sealed trait OrgUse { self: Product =>

  final def name: String =
    self.productPrefix.toLowerCase()
}

object OrgUse {

  case object Correspondent extends OrgUse
  case object Disabled extends OrgUse

  def correspondent: OrgUse = Correspondent
  def disabled: OrgUse = Disabled

  val all: NonEmptyList[OrgUse] =
    NonEmptyList.of(correspondent, disabled)

  val notDisabled: NonEmptyList[OrgUse] =
    NonEmptyList.of(correspondent)

  def fromString(str: String): Either[String, OrgUse] =
    str.toLowerCase() match {
      case "correspondent" =>
        Right(Correspondent)
      case "disabled" =>
        Right(Disabled)
      case _ =>
        Left(s"Unknown organization-use: $str")
    }

  def unsafeFromString(str: String): OrgUse =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[OrgUse] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[OrgUse] =
    Encoder.encodeString.contramap(_.name)
}
