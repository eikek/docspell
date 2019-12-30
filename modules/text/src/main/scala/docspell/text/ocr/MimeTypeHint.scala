package docspell.text.ocr

case class MimeTypeHint(filename: Option[String], advertised: Option[String]) {}

object MimeTypeHint {
  val none = MimeTypeHint(None, None)
}
