/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.Decoder
import io.circe.Encoder

sealed trait EquipmentUse { self: Product =>

  final def name: String =
    self.productPrefix.toLowerCase()
}

object EquipmentUse {

  case object Concerning extends EquipmentUse
  case object Disabled   extends EquipmentUse

  def concerning: EquipmentUse = Concerning
  def disabled: EquipmentUse   = Disabled

  val all: NonEmptyList[EquipmentUse] =
    NonEmptyList.of(concerning, disabled)

  val notDisabled: NonEmptyList[EquipmentUse] =
    NonEmptyList.of(concerning)

  def fromString(str: String): Either[String, EquipmentUse] =
    str.toLowerCase() match {
      case "concerning" =>
        Right(Concerning)
      case "disabled" =>
        Right(Disabled)
      case _ =>
        Left(s"Unknown equipment-use: $str")
    }

  def unsafeFromString(str: String): EquipmentUse =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[EquipmentUse] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[EquipmentUse] =
    Encoder.encodeString.contramap(_.name)
}
