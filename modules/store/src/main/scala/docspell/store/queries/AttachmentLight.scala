package docspell.store.queries

import docspell.common._

case class AttachmentLight(
    id: Ident,
    position: Int,
    name: Option[String],
    pageCount: Option[Int]
)
