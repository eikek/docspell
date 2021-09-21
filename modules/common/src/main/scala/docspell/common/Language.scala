/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

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

  case object Portuguese extends Language {
    val iso2 = "pt"
    val iso3 = "por"
  }

  case object Czech extends Language {
    val iso2 = "cs"
    val iso3 = "ces"
  }

  case object Danish extends Language {
    val iso2 = "da"
    val iso3 = "dan"
  }

  case object Finnish extends Language {
    val iso2 = "fi"
    val iso3 = "fin"
  }

  case object Norwegian extends Language {
    val iso2 = "no"
    val iso3 = "nor"
  }

  case object Swedish extends Language {
    val iso2 = "sv"
    val iso3 = "swe"
  }

  case object Russian extends Language {
    val iso2 = "ru"
    val iso3 = "rus"
  }

  case object Romanian extends Language {
    val iso2 = "ro"
    val iso3 = "ron"
  }

  case object Dutch extends Language {
    val iso2 = "nl"
    val iso3 = "nld"
  }

  case object Latvian extends Language {
    val iso2 = "lv"
    val iso3 = "lav"
  }

  case object Japanese extends Language {
    val iso2 = "ja"
    val iso3 = "jpn"
  }

  case object Hebrew extends Language {
    val iso2 = "he"
    val iso3 = "heb"
  }

  val all: List[Language] =
    List(
      German,
      English,
      French,
      Italian,
      Spanish,
      Dutch,
      Portuguese,
      Czech,
      Danish,
      Finnish,
      Norwegian,
      Swedish,
      Russian,
      Romanian,
      Latvian,
      Japanese,
      Hebrew
    )

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
