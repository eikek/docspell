package docspell.ftspsql

import cats.data.NonEmptyList

sealed trait PgQueryParser {
  def name: String
}

object PgQueryParser {

  case object ToTsQuery extends PgQueryParser {
    val name = "to_tsquery"
  }
  case object Plain extends PgQueryParser {
    val name = "plainto_tsquery"
  }
  case object Phrase extends PgQueryParser {
    val name = "phraseto_tsquery"
  }
  case object Websearch extends PgQueryParser {
    val name = "websearch_to_tsquery"
  }

  val all: NonEmptyList[PgQueryParser] =
    NonEmptyList.of(ToTsQuery, Plain, Phrase, Websearch)

  def fromName(name: String): Either[String, PgQueryParser] =
    all.find(_.name.equalsIgnoreCase(name)).toRight(s"Unknown pg query parser: $name")

  def unsafeFromName(name: String): PgQueryParser =
    fromName(name).fold(sys.error, identity)
}
