package docspell.common

import cats.Order
import cats.implicits._

import io.circe.{Decoder, Encoder}

sealed trait Priority { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object Priority {

  case object High extends Priority

  case object Low extends Priority

  def fromString(str: String): Either[String, Priority] =
    str.toLowerCase match {
      case "high" => Right(High)
      case "low"  => Right(Low)
      case _      => Left(s"Invalid priority: $str")
    }

  def unsafe(str: String): Priority =
    fromString(str).fold(sys.error, identity)

  def fromInt(n: Int): Priority =
    if (n <= toInt(Low)) Low
    else High

  def toInt(p: Priority): Int =
    p match {
      case Low  => 0
      case High => 10
    }

  implicit val priorityOrder: Order[Priority] =
    Order.by[Priority, Int](toInt)

  implicit val jsonEncoder: Encoder[Priority] =
    Encoder.encodeString.contramap(_.name)
  implicit val jsonDecoder: Decoder[Priority] =
    Decoder.decodeString.emap(fromString)
}
