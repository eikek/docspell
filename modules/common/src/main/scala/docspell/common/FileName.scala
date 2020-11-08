package docspell.common

case class FileName private (name: String) {

  private[this] val (base, ext) =
    name.lastIndexOf('.') match {
      case -1 => (name, None)
      case n  => (name.take(n), Some(name.drop(n + 1)))
    }

  /** Returns the name part without the extension. If there is no
    * extension, it is the same as fullname.
    */
  def baseName: String =
    base

  /** Returns the extension part if available without the dot. */
  def extension: Option[String] =
    ext

  def fullName: String =
    name

  /** Creates a new name where part is spliced into the name before the
    * extension, separated by separator.
    */
  def withPart(part: String, sep: Char): FileName =
    if (part.isEmpty()) this
    else
      ext
        .map(e => new FileName(s"${base}${sep}${part}.${e}"))
        .getOrElse(new FileName(s"${base}${sep}${part}"))

  /** Create a new name using the given extension. */
  def withExtension(newExt: String): FileName =
    if (newExt.isEmpty()) new FileName(base)
    else new FileName(s"${base}.${newExt}")

}
object FileName {

  def apply(name: String): FileName =
    Option(name)
      .map(_.trim)
      .filter(_.nonEmpty)
      .map(n => new FileName(n))
      .getOrElse(new FileName("unknown-file"))
}
