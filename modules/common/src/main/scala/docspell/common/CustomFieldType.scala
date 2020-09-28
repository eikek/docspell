package docspell.common

import io.circe._

sealed trait CustomFieldType { self: Product =>

  final def name: String =
    self.productPrefix.toLowerCase()

}

object CustomFieldType {

  case object Text extends CustomFieldType

  case object Numeric extends CustomFieldType

  case object Date extends CustomFieldType

  case object Bool extends CustomFieldType

  case object Money extends CustomFieldType

  def text: CustomFieldType    = Text
  def numeric: CustomFieldType = Numeric
  def date: CustomFieldType    = Date
  def bool: CustomFieldType    = Bool
  def money: CustomFieldType   = Money

  val all: List[CustomFieldType] = List(Text, Numeric, Date, Bool, Money)

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
