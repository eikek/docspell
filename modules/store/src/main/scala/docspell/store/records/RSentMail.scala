package docspell.store.records

import fs2.Stream
import cats.effect._
import cats.implicits._
import cats.data.NonEmptyList
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import emil.MailAddress
import cats.data.OptionT

case class RSentMail(
    id: Ident,
    uid: Ident,
    messageId: String,
    sender: MailAddress,
    connName: Ident,
    subject: String,
    recipients: List[MailAddress],
    body: String,
    created: Timestamp
) {}

object RSentMail {

  def apply[F[_]: Sync](
      uid: Ident,
      messageId: String,
      sender: MailAddress,
      connName: Ident,
      subject: String,
      recipients: List[MailAddress],
      body: String
  ): F[RSentMail] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RSentMail(
      id,
      uid,
      messageId,
      sender,
      connName,
      subject,
      recipients,
      body,
      now
    )

  def forItem(
      itemId: Ident,
      accId: AccountId,
      messageId: String,
      sender: MailAddress,
      connName: Ident,
      subject: String,
      recipients: List[MailAddress],
      body: String
  ): OptionT[ConnectionIO, (RSentMail, RSentMailItem)] =
    for {
      user <- OptionT(RUser.findByAccount(accId))
      sm <- OptionT.liftF(
        RSentMail[ConnectionIO](
          user.uid,
          messageId,
          sender,
          connName,
          subject,
          recipients,
          body
        )
      )
      si <- OptionT.liftF(RSentMailItem[ConnectionIO](itemId, sm.id, Some(sm.created)))
    } yield (sm, si)

  val table = fr"sentmail"

  object Columns {
    val id         = Column("id")
    val uid        = Column("uid")
    val messageId  = Column("message_id")
    val sender     = Column("sender")
    val connName   = Column("conn_name")
    val subject    = Column("subject")
    val recipients = Column("recipients")
    val body       = Column("body")
    val created    = Column("created")

    val all = List(
      id,
      uid,
      messageId,
      sender,
      connName,
      subject,
      recipients,
      body,
      created
    )
  }

  import Columns._

  def insert(v: RSentMail): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      sql"${v.id},${v.uid},${v.messageId},${v.sender},${v.connName},${v.subject},${v.recipients},${v.body},${v.created}"
    ).update.run

  def findByUser(userId: Ident): Stream[ConnectionIO, RSentMail] =
    selectSimple(all, table, uid.is(userId)).query[RSentMail].stream

  def delete(mailId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(mailId)).update.run

  def deleteByItem(item: Ident): ConnectionIO[Int] =
    for {
      list <- RSentMailItem.findSentMailIdsByItem(item)
      n1   <- RSentMailItem.deleteAllByItem(item)
      n0 <- NonEmptyList.fromList(list.toList) match {
        case Some(nel) => deleteFrom(table, id.isIn(nel)).update.run
        case None      => 0.pure[ConnectionIO]
      }
    } yield n0 + n1

}
