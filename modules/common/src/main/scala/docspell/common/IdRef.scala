package docspell.common

import io.circe._
import io.circe.generic.semiauto._

case class IdRef(id: Ident, name: String) {

}

object IdRef {

  implicit val jsonEncoder: Encoder[IdRef] =
    deriveEncoder[IdRef]
  implicit val jsonDecoder: Decoder[IdRef] =
    deriveDecoder[IdRef]
}