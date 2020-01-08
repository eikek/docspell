package docspell.store.records

import fs2.Stream
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import emil.MailAddress

case class RSentMail(
    id: Ident,
    uid: Ident,
    itemId: Ident,
    messageId: String,
    sender: MailAddress,
    subject: String,
    recipients: List[MailAddress],
    body: String,
    created: Timestamp
) {}

object RSentMail {

  val table = fr"sentmail"

  object Columns {
    val id            = Column("id")
    val uid           = Column("uid")
    val itemId          = Column("item_id")
    val messageId      = Column("message_id")
    val sender      = Column("sender")
    val subject      = Column("subject")
    val recipients      = Column("recipients")
    val body       = Column("body")
    val created       = Column("created")

    val all = List(
      id,
      uid,
      itemId,
      messageId,
      sender,
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
      sql"${v.id},${v.uid},${v.itemId},${v.messageId},${v.sender},${v.subject},${v.recipients},${v.body},${v.created}"
    ).update.run

  def findByUser(userId: Ident): Stream[ConnectionIO, RSentMail] =
    selectSimple(all, table, uid.is(userId)).query[RSentMail].stream

}
