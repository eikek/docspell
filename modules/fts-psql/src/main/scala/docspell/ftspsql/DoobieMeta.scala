package docspell.ftspsql

import docspell.common._
import doobie._
import doobie.util.log.Success

trait DoobieMeta {

  implicit val sqlLogging: LogHandler = LogHandler {
    case e @ Success(_, _, _, _) =>
      DoobieMeta.logger.debug("SQL " + e)
    case e =>
      DoobieMeta.logger.error(s"SQL Failure: $e")
  }

  implicit val metaIdent: Meta[Ident] =
    Meta[String].timap(Ident.unsafe)(_.id)

  implicit val metaLanguage: Meta[Language] =
    Meta[String].timap(Language.unsafe)(_.iso3)

}

object DoobieMeta {
  private val logger = org.log4s.getLogger
}
