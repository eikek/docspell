package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait Language { self: Product =>

  final def name: String =
    productPrefix.toLowerCase

  def iso2: String

  def iso3: String

  val allowsNLP: Boolean = false

  private[common] def allNames =
    Set(name, iso3, iso2)
}

object Language {
  sealed trait NLPLanguage extends Language with Product {
    override val allowsNLP = true
  }
  object NLPLanguage {
    val all: NonEmptyList[NLPLanguage] = NonEmptyList.of(German, English, French)
  }

  case object German extends NLPLanguage {
    val iso2 = "de"
    val iso3 = "deu"
  }

  case object English extends NLPLanguage {
    val iso2 = "en"
    val iso3 = "eng"
  }

  case object French extends NLPLanguage {
    val iso2 = "fr"
    val iso3 = "fra"
  }

  case object Italian extends Language {
    val iso2 = "it"
    val iso3 = "ita"
  }

  case object Spanish extends Language {
    val iso2 = "es"
    val iso3 = "spa"
  }

  val all: List[Language] = List(German, English, French, Italian, Spanish)

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
