package docspell.common

import docspell.common.syntax.all._
import io.circe.{Decoder, Encoder}

/** A MIME Type impl with just enough features for the use here.
  */
case class MimeType(primary: String, sub: String) {

  def asString: String =
    s"$primary/$sub"

  def matches(other: MimeType): Boolean =
    primary == other.primary &&
      (sub == other.sub || sub == "*")
}

object MimeType {

  def application(sub: String): MimeType =
    MimeType("application", partFromString(sub).throwLeft)

  def text(sub: String): MimeType =
    MimeType("text", partFromString(sub).throwLeft)

  def image(sub: String): MimeType =
    MimeType("image", partFromString(sub).throwLeft)

  private[this] val validChars: Set[Char] =
    (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "*-").toSet

  def parse(str: String): Either[String, MimeType] =
    str.indexOf('/') match {
      case -1 => Left(s"Invalid MIME type: $str")
      case n =>
        for {
          prim <- partFromString(str.substring(0, n))
          sub  <- partFromString(str.substring(n + 1))
        } yield MimeType(prim.toLowerCase, sub.toLowerCase)
    }

  def unsafe(str: String): MimeType =
    parse(str).throwLeft

  private def partFromString(s: String): Either[String, String] =
    if (s.forall(validChars.contains)) Right(s)
    else Left(s"Invalid identifier: $s. Allowed chars: ${validChars.mkString}")

  val octetStream = application("octet-stream")
  val pdf         = application("pdf")
  val png         = image("png")
  val jpeg        = image("jpeg")
  val tiff        = image("tiff")
  val html        = text("html")
  val plain       = text("plain")

  implicit val jsonEncoder: Encoder[MimeType] =
    Encoder.encodeString.contramap(_.asString)

  implicit val jsonDecoder: Decoder[MimeType] =
    Decoder.decodeString.emap(parse)
}
