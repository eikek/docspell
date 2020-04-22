package docspell.joex.notify

import yamusca.implicits._
import yamusca.imports._

import docspell.common._
import docspell.store.queries.QItem
import docspell.joex.notify.YamuscaConverter._

case class MailContext(
    items: List[MailContext.ItemData],
    more: Boolean,
    account: AccountId,
    itemUri: Option[LenientUri]
)

object MailContext {

  def from(
      items: Vector[QItem.ListItem],
      max: Int,
      account: AccountId,
      itemBaseUri: Option[LenientUri]
  ): MailContext =
    MailContext(
      items.take(max - 1).map(ItemData.apply).toList.sortBy(_.dueDate),
      items.sizeCompare(max) >= 0,
      account,
      itemBaseUri
    )

  case class ItemData(
      id: Ident,
      name: String,
      date: Timestamp,
      dueDate: Option[Timestamp],
      source: String
  )

  object ItemData {

    def apply(i: QItem.ListItem): ItemData =
      ItemData(i.id, i.name, i.date, i.dueDate, i.source)

    implicit def yamusca: ValueConverter[ItemData] =
      ValueConverter.deriveConverter[ItemData]
  }

  implicit val yamusca: ValueConverter[MailContext] =
    ValueConverter.deriveConverter[MailContext]

}
