package docspell.common

case class MimeTypeHint(filename: Option[String], advertised: Option[String]) {}

object MimeTypeHint {
  val none = MimeTypeHint(None, None)

  def filename(name: String): MimeTypeHint =
    MimeTypeHint(Some(name), None)

  def advertised(mimeType: MimeType): MimeTypeHint =
    advertised(mimeType.asString)

  def advertised(mimeType: String): MimeTypeHint =
    MimeTypeHint(None, Some(mimeType))
}
