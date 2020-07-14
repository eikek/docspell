package docspell.ftsclient

import docspell.common._

final case class FtsMigration[F[_]](
    version: Int,
    engine: Ident,
    description: String,
    task: F[FtsMigration.Result]
)

object FtsMigration {

  sealed trait Result
  object Result {
    case object WorkDone   extends Result
    case object ReIndexAll extends Result
    case object IndexAll   extends Result

    def workDone: Result   = WorkDone
    def reIndexAll: Result = ReIndexAll
    def indexAll: Result   = IndexAll
  }
}
