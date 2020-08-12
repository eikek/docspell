package docspell.common

import io.circe._
import io.circe.generic.semiauto._

case class ConvertAllPdfArgs(collective: Option[Ident])

object ConvertAllPdfArgs {
  val taskName = Ident.unsafe("submit-pdf-migration-tasks")
  implicit val jsonDecoder: Decoder[ConvertAllPdfArgs] =
    deriveDecoder[ConvertAllPdfArgs]
  implicit val jsonEncoder: Encoder[ConvertAllPdfArgs] =
    deriveEncoder[ConvertAllPdfArgs]
}
