package docspell.joex.notify

import docspell.common._
import docspell.joex.notify.YamuscaConverter._
import docspell.store.queries.ListItem

import yamusca.implicits._
import yamusca.imports._

/** The context for rendering the e-mail template. */
case class MailContext(
    items: List[MailContext.ItemData],
    more: Boolean,
    account: AccountId,
    username: String,
    itemUri: Option[LenientUri]
)

object MailContext {

  def from(
      items: Vector[ListItem],
      max: Int,
      account: AccountId,
      itemBaseUri: Option[LenientUri],
      now: Timestamp
  ): MailContext =
    MailContext(
      items.take(max - 1).map(ItemData(now)).toList.sortBy(_.dueDate),
      items.sizeCompare(max) >= 0,
      account,
      account.user.id.capitalize,
      itemBaseUri
    )

  case class ItemData(
      id: Ident,
      name: String,
      date: Timestamp,
      dueDate: Option[Timestamp],
      source: String,
      overDue: Boolean,
      dueIn: Option[String],
      corrOrg: Option[String]
  )

  object ItemData {

    def apply(now: Timestamp)(i: ListItem): ItemData = {
      val dueIn = i.dueDate.map(dt => Timestamp.daysBetween(now, dt))
      val dueInLabel = dueIn.map {
        case 0          => "**today**"
        case 1          => "**tomorrow**"
        case -1         => s"**yesterday**"
        case n if n > 0 => s"in $n days"
        case n          => s"${n * -1} days ago"
      }
      ItemData(
        i.id,
        i.name,
        i.date,
        i.dueDate,
        i.source,
        dueIn.exists(_ < 0),
        dueInLabel,
        i.corrOrg.map(_.name)
      )
    }

    implicit def yamusca: ValueConverter[ItemData] =
      ValueConverter.deriveConverter[ItemData]
  }

  implicit val yamusca: ValueConverter[MailContext] =
    ValueConverter.deriveConverter[MailContext]

}
