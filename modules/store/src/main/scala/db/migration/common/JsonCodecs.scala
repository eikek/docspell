package db.migration.common

import emil.MailAddress
import emil.javamail.syntax._
import io.circe.{Decoder, Encoder}

trait JsonCodecs {

  implicit val jsonEncoder: Encoder[MailAddress] =
    Encoder.encodeString.contramap(_.asUnicodeString)
  implicit val jsonDecoder: Decoder[MailAddress] =
    Decoder.decodeString.emap(MailAddress.parse)

}
