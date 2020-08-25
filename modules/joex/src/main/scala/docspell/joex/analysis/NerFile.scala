package docspell.joex.analysis

import java.nio.file.Path

import cats.effect._
import cats.implicits._

import docspell.analysis.split.TextSplitter
import docspell.common._
import docspell.store.queries.QCollective

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

case class NerFile(collective: Ident, updated: Timestamp, creation: Timestamp) {
  def nerFilePath(directory: Path): Path =
    NerFile.nerFilePath(directory, collective)

  def jsonFilePath(directory: Path) =
    NerFile.jsonFilePath(directory, collective)
}

object NerFile {
  implicit val jsonDecoder: Decoder[NerFile] =
    deriveDecoder[NerFile]

  implicit val jsonEncoder: Encoder[NerFile] =
    deriveEncoder[NerFile]

  private def nerFilePath(directory: Path, collective: Ident): Path =
    directory.resolve(s"${collective.id}.txt")

  private def jsonFilePath(directory: Path, collective: Ident): Path =
    directory.resolve(s"${collective.id}.json")

  def find[F[_]: Sync: ContextShift](
      collective: Ident,
      directory: Path,
      blocker: Blocker
  ): F[Option[NerFile]] = {
    val file = jsonFilePath(directory, collective)
    File.existsNonEmpty[F](file).flatMap {
      case true =>
        File
          .readJson[F, NerFile](file, blocker)
          .map(_.some)
      case false =>
        (None: Option[NerFile]).pure[F]
    }
  }

  def mkNerConfig(names: QCollective.Names): String = {
    val orgs = names.org
      .flatMap(Pattern(3))
      .distinct
      .map(_.toRow("ORGANIZATION", "LOCATION,PERSON,MISC"))

    val pers =
      names.pers
        .flatMap(Pattern(2))
        .distinct
        .map(_.toRow("PERSON", "LOCATION,MISC"))

    val equips =
      names.equip
        .flatMap(Pattern(1))
        .distinct
        .map(_.toRow("MISC", "LOCATION"))

    (orgs ++ pers ++ equips).mkString("\n")
  }
  case class Pattern(value: String, weight: Int) {
    def toRow(tag: String, overrideTags: String): String =
      s"$value\t$tag\t$overrideTags\t$weight"
  }

  object Pattern {
    def apply(weight: Int)(str: String): Vector[Pattern] = {
      val delims = " \t\n\r".toSet
      val words =
        TextSplitter
          .split(str, delims)
          .map(_.toLower.value.trim)
          .filter(_.nonEmpty)
          .toVector
          .map(w => s"(?i)${w}")
      val tokens =
        TextSplitter
          .splitToken(str, delims)
          .map(_.toLower.value.trim)
          .filter(_.nonEmpty)
          .toVector
          .take(3)
          .map(w => s"(?i)${w}")

      tokens.map(t => Pattern(t, weight)).prepended(Pattern(words.mkString(" "), weight))
    }
  }
}
