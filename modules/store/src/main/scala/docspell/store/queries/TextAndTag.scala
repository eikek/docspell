package docspell.store.queries

import docspell.common._

case class TextAndTag(itemId: Ident, text: String, tag: Option[TextAndTag.TagName])

object TextAndTag {
  case class TagName(id: Ident, name: String)
}
