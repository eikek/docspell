/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.LocalDate

import cats.data.NonEmptyList
import cats.implicits._

import io.circe._

sealed trait CustomFieldType { self: Product =>

  type ValueType

  final def name: String =
    self.productPrefix.toLowerCase()

  def valueString(value: ValueType): String

  def parseValue(value: String): Either[String, ValueType]
}

object CustomFieldType {

  case object Text extends CustomFieldType {

    type ValueType = String

    def valueString(value: String): String =
      value

    def parseValue(value: String): Either[String, String] =
      Option(value)
        .map(_.trim)
        .filter(_.nonEmpty)
        .toRight("Empty values are not allowed.")
  }

  case object Numeric extends CustomFieldType {
    type ValueType = BigDecimal

    def valueString(value: BigDecimal): String =
      value.toString

    def parseValue(value: String): Either[String, BigDecimal] =
      Either
        .catchNonFatal(BigDecimal.exact(value))
        .leftMap(_ => s"Could not parse decimal value from: $value")
  }

  case object Date extends CustomFieldType {
    type ValueType = LocalDate

    def valueString(value: LocalDate): String =
      value.toString

    def parseValue(value: String): Either[String, LocalDate] =
      Either
        .catchNonFatal(LocalDate.parse(value))
        .leftMap(_.getMessage)
  }

  case object Bool extends CustomFieldType {
    type ValueType = Boolean

    def valueString(value: Boolean): String =
      value.toString

    def parseValue(value: String): Either[String, Boolean] =
      Option(value)
        .map(_.trim)
        .filter(_.nonEmpty)
        .toRight("Empty values not allowed")
        .map(_.equalsIgnoreCase("true"))

  }

  case object Money extends CustomFieldType {
    type ValueType = BigDecimal

    def valueString(value: BigDecimal): String =
      Numeric.valueString(value)

    def parseValue(value: String): Either[String, BigDecimal] =
      Numeric.parseValue(value).map(round)

    def round(v: BigDecimal): BigDecimal =
      v.setScale(2, BigDecimal.RoundingMode.HALF_EVEN)
  }

  def text: CustomFieldType    = Text
  def numeric: CustomFieldType = Numeric
  def date: CustomFieldType    = Date
  def bool: CustomFieldType    = Bool
  def money: CustomFieldType   = Money

  val all: NonEmptyList[CustomFieldType] =
    NonEmptyList.of(Text, Numeric, Date, Bool, Money)

  def fromString(str: String): Either[String, CustomFieldType] =
    str.toLowerCase match {
      case "text"    => Right(text)
      case "numeric" => Right(numeric)
      case "date"    => Right(date)
      case "bool"    => Right(bool)
      case "money"   => Right(money)
      case _         => Left(s"Unknown custom field: $str")
    }

  def unsafe(str: String): CustomFieldType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[CustomFieldType] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[CustomFieldType] =
    Encoder.encodeString.contramap(_.name)
}
