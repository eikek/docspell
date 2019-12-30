package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait Direction {
  self: Product =>

  def name: String =
    productPrefix.toLowerCase
}

object Direction {

  case object Incoming extends Direction
  case object Outgoing extends Direction

  def incoming: Direction = Incoming
  def outgoing: Direction = Outgoing

  def parse(str: String): Either[String, Direction] =
    str.toLowerCase match {
      case "incoming" => Right(Incoming)
      case "outgoing" => Right(Outgoing)
      case _          => Left(s"No direction: $str")
    }

  def unsafe(str: String): Direction =
    parse(str).fold(sys.error, identity)

  def isIncoming(dir: Direction): Boolean =
    dir == Direction.Incoming

  def isOutgoing(dir: Direction): Boolean =
    dir == Direction.Outgoing

  implicit val directionEncoder: Encoder[Direction] =
    Encoder.encodeString.contramap(_.name)

  implicit val directionDecoder: Decoder[Direction] =
    Decoder.decodeString.emap(Direction.parse)

}
