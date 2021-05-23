package docspell.common

final case class ItemQueryString(query: String) {
  def isEmpty: Boolean =
    query.isEmpty
}

object ItemQueryString {

  def apply(qs: Option[String]): ItemQueryString =
    ItemQueryString(qs.getOrElse(""))
}
