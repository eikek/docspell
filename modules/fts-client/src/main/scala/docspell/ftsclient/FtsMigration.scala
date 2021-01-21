package docspell.ftsclient

import cats.Functor
import cats.implicits._

import docspell.common._

final case class FtsMigration[F[_]](
    version: Int,
    engine: Ident,
    description: String,
    task: F[FtsMigration.Result]
) {

  def changeResult(f: FtsMigration.Result => FtsMigration.Result)(implicit
      F: Functor[F]
  ): FtsMigration[F] =
    copy(task = task.map(f))
}

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
