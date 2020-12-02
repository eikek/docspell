package docspell.common

import io.circe._
import io.circe.generic.semiauto._

case class PersonRef(id: Ident, name: String, organization: Option[Ident]) {

  def toIdRef: IdRef =
    IdRef(id, name)
}

object PersonRef {

  implicit val jsonEncoder: Encoder[PersonRef] =
    deriveEncoder[PersonRef]
  implicit val jsonDecoder: Decoder[PersonRef] =
    deriveDecoder[PersonRef]
}
