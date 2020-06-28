package docspell.store.records

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RSentMailItem(
    id: Ident,
    itemId: Ident,
    sentMailId: Ident,
    created: Timestamp
) {}

object RSentMailItem {

  def apply[F[_]: Sync](
      itemId: Ident,
      sentmailId: Ident,
      created: Option[Timestamp] = None
  ): F[RSentMailItem] =
    for {
      id  <- Ident.randomId[F]
      now <- created.map(_.pure[F]).getOrElse(Timestamp.current[F])
    } yield RSentMailItem(id, itemId, sentmailId, now)

  val table = fr"sentmailitem"

  object Columns {
    val id         = Column("id")
    val itemId     = Column("item_id")
    val sentMailId = Column("sentmail_id")
    val created    = Column("created")

    val all = List(
      id,
      itemId,
      sentMailId,
      created
    )
  }

  import Columns._

  def insert(v: RSentMailItem): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      sql"${v.id},${v.itemId},${v.sentMailId},${v.created}"
    ).update.run

  def deleteMail(mailId: Ident): ConnectionIO[Int] =
    deleteFrom(table, sentMailId.is(mailId)).update.run

  def findSentMailIdsByItem(item: Ident): ConnectionIO[Set[Ident]] =
    selectSimple(Seq(sentMailId), table, itemId.is(item)).query[Ident].to[Set]

  def deleteAllByItem(item: Ident): ConnectionIO[Int] =
    deleteFrom(table, itemId.is(item)).update.run
}
