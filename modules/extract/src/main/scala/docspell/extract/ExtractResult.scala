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
  def unsupportedFormat(mt: MimeType): ExtractResult =
    UnsupportedFormat(mt)

  case class Failure(ex: Throwable) extends ExtractResult {
    val textOption = None
  }
  def failure(ex: Throwable): ExtractResult =
    Failure(ex)

  case class Success(text: String) extends ExtractResult {
    val textOption = Some(text)
  }
  def success(text: String): ExtractResult =
    Success(text)

  def fromTry(r: Try[String]): ExtractResult =
    r.fold(Failure.apply, Success.apply)

  def fromEither(e: Either[Throwable, String]): ExtractResult =
    e.fold(failure, success)

}
