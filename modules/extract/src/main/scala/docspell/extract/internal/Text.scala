package docspell.extract.internal

case class Text(raw: String) {

  private lazy val textValue =
    raw.trim.replace("\u0000", "")

  def length: Int =
    textValue.length

  def value: String =
    textValue
}

object Text {

  def apply(ot: Option[String]): Text =
    Text(ot.getOrElse(""))

}
