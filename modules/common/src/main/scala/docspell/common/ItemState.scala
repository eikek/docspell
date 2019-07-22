package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait ItemState { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object ItemState {

  case object Premature extends ItemState
  case object Processing extends ItemState
  case object Created extends ItemState
  case object Confirmed extends ItemState

  def fromString(str: String): Either[String, ItemState] =
    str.toLowerCase match {
      case "premature" => Right(Premature)
      case "processing" => Right(Processing)
      case "created" => Right(Created)
      case "confirmed" => Right(Confirmed)
      case _ => Left(s"Invalid item state: $str")
    }

  def unsafe(str: String): ItemState =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[ItemState] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[ItemState] =
    Encoder.encodeString.contramap(_.name)
}

