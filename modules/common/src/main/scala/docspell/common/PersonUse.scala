package docspell.common

import cats.data.NonEmptyList

import io.circe.Decoder
import io.circe.Encoder

sealed trait PersonUse { self: Product =>

  final def name: String =
    self.productPrefix.toLowerCase()
}

object PersonUse {

  case object Correspondent extends PersonUse
  case object Concerning    extends PersonUse
  case object Both          extends PersonUse
  case object Disabled      extends PersonUse

  def concerning: PersonUse    = Concerning
  def correspondent: PersonUse = Correspondent
  def both: PersonUse          = Both

  val concerningAndBoth: NonEmptyList[PersonUse] =
    NonEmptyList.of(Concerning, Both)

  val correspondentAndBoth: NonEmptyList[PersonUse] =
    NonEmptyList.of(Correspondent, Both)

  def fromString(str: String): Either[String, PersonUse] =
    str.toLowerCase() match {
      case "correspondent" =>
        Right(Correspondent)
      case "concerning" =>
        Right(Concerning)
      case "both" =>
        Right(Both)
      case "disabled" =>
        Right(Disabled)
      case _ =>
        Left(s"Unknown person-use: $str")
    }

  def unsafeFromString(str: String): PersonUse =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[PersonUse] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[PersonUse] =
    Encoder.encodeString.contramap(_.name)
}
