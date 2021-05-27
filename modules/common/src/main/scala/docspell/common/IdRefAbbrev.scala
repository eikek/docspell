package docspell.common

import cats.Order

import io.circe._
import io.circe.generic.semiauto._

case class IdRefAbbrev(id: Ident, name: String, shortName: Option[String]) {

  def asIdRef: IdRef = IdRef(id, name)
}

object IdRefAbbrev {

  implicit val jsonEncoder: Encoder[IdRefAbbrev] =
    deriveEncoder[IdRefAbbrev]
  implicit val jsonDecoder: Decoder[IdRefAbbrev] =
    deriveDecoder[IdRefAbbrev]

  implicit val order: Order[IdRefAbbrev] =
    Order.by(_.id)
}
