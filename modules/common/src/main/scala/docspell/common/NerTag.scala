package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait NerTag { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object NerTag {

  case object Organization extends NerTag
  case object Person extends NerTag
  case object Location extends NerTag
  case object Misc extends NerTag
  case object Email extends NerTag
  case object Website extends NerTag
  case object Date extends NerTag

  val all: List[NerTag] = List(Organization, Person, Location)

  def fromString(str: String): Either[String, NerTag] =
    str.toLowerCase match {
      case "organization" => Right(Organization)
      case "person" => Right(Person)
      case "location" => Right(Location)
      case "misc" => Right(Misc)
      case "email" => Right(Email)
      case "website" => Right(Website)
      case "date" => Right(Date)
      case _ => Left(s"Invalid ner tag: $str")
    }

  def unsafe(str: String): NerTag =
    fromString(str).fold(sys.error, identity)


  implicit val jsonDecoder: Decoder[NerTag] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[NerTag] =
    Encoder.encodeString.contramap(_.name)
}
