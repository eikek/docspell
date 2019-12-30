package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait Language { self: Product =>

  final def name: String =
    productPrefix.toLowerCase

  def iso2: String

  def iso3: String

  private[common] def allNames =
    Set(name, iso3, iso2)
}

object Language {

  case object German extends Language {
    val iso2 = "de"
    val iso3 = "deu"
  }

  case object English extends Language {
    val iso2 = "en"
    val iso3 = "eng"
  }

  val all: List[Language] = List(German, English)

  def fromString(str: String): Either[String, Language] = {
    val lang = str.toLowerCase
    all.find(_.allNames.contains(lang)).toRight(s"Unsupported or invalid language: $str")
  }

  def unsafe(str: String): Language =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[Language] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[Language] =
    Encoder.encodeString.contramap(_.iso3)
}
