package docspell.backend.ops

import docspell.common._

sealed trait SendResult

object SendResult {

  case class Success(id: Ident) extends SendResult

  case class Failure(ex: Throwable) extends SendResult
}
