package docspell.common

case class ItemQueryString(query: String)

object ItemQueryString {

  def apply(qs: Option[String]): ItemQueryString =
    ItemQueryString(qs.getOrElse(""))
}
