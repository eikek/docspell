package docspell.extract

import docspell.common.MimeType

import scala.util.Try

sealed trait ExtractResult {

  def textOption: Option[String]

}

object ExtractResult {

  case class UnsupportedFormat(mime: MimeType) extends ExtractResult {
    val textOption = None
  }
  case class Failure(ex: Throwable) extends ExtractResult {
    val textOption = None
  }
  case class Success(text: String) extends ExtractResult {
    val textOption = Some(text)
  }

  def fromTry(r: Try[String]): ExtractResult =
    r.fold(Failure.apply, Success.apply)


}
