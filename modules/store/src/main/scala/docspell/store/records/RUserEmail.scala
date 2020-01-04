package docspell.store.records

import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import emil.{MailAddress, SSLType}

case class RUserEmail(
    id: Ident,
    uid: Ident,
    name: String,
    smtpHost: String,
    smtpPort: Int,
    smtpUser: String,
    smtpPassword: Password,
    smtpSsl: SSLType,
    smtpCertCheck: Boolean,
    mailFrom: MailAddress,
    mailReplyTo: Option[MailAddress],
    created: Timestamp
) {}

object RUserEmail {

  val table = fr"useremail"

  object Columns {
    val id            = Column("id")
    val uid           = Column("uid")
    val name          = Column("name")
    val smtpHost      = Column("smtp_host")
    val smtpPort      = Column("smtp_port")
    val smtpUser      = Column("smtp_user")
    val smtpPass      = Column("smtp_password")
    val smtpSsl       = Column("smtp_ssl")
    val smtpCertCheck = Column("smtp_certcheck")
    val mailFrom      = Column("mail_from")
    val mailReplyTo   = Column("mail_replyto")
    val created       = Column("created")

    val all = List(
      id,
      uid,
      name,
      smtpHost,
      smtpPort,
      smtpUser,
      smtpPass,
      smtpSsl,
      smtpCertCheck,
      mailFrom,
      mailReplyTo,
      created
    )
  }

  import Columns._

  def insert(v: RUserEmail): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      sql"${v.id},${v.uid},${v.name},${v.smtpHost},${v.smtpPort},${v.smtpUser},${v.smtpPassword},${v.smtpSsl},${v.smtpCertCheck},${v.mailFrom},${v.mailReplyTo},${v.created}"
    ).update.run

  def findByUser(userId: Ident): ConnectionIO[Vector[RUserEmail]] =
    selectSimple(all, table, uid.is(userId)).query[RUserEmail].to[Vector]

}
