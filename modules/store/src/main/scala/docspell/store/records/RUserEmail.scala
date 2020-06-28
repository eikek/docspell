package docspell.store.records

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._
import emil.{MailAddress, MailConfig, SSLType}

case class RUserEmail(
    id: Ident,
    uid: Ident,
    name: Ident,
    smtpHost: String,
    smtpPort: Option[Int],
    smtpUser: Option[String],
    smtpPassword: Option[Password],
    smtpSsl: SSLType,
    smtpCertCheck: Boolean,
    mailFrom: MailAddress,
    mailReplyTo: Option[MailAddress],
    created: Timestamp
) {

  def toMailConfig: MailConfig = {
    val port = smtpPort.map(p => s":$p").getOrElse("")
    MailConfig(
      s"smtp://$smtpHost$port",
      smtpUser.getOrElse(""),
      smtpPassword.map(_.pass).getOrElse(""),
      smtpSsl,
      !smtpCertCheck
    )
  }
}

object RUserEmail {

  def apply[F[_]: Sync](
      uid: Ident,
      name: Ident,
      smtpHost: String,
      smtpPort: Option[Int],
      smtpUser: Option[String],
      smtpPassword: Option[Password],
      smtpSsl: SSLType,
      smtpCertCheck: Boolean,
      mailFrom: MailAddress,
      mailReplyTo: Option[MailAddress]
  ): F[RUserEmail] =
    for {
      now <- Timestamp.current[F]
      id  <- Ident.randomId[F]
    } yield RUserEmail(
      id,
      uid,
      name,
      smtpHost,
      smtpPort,
      smtpUser,
      smtpPassword,
      smtpSsl,
      smtpCertCheck,
      mailFrom,
      mailReplyTo,
      now
    )

  def fromAccount(
      accId: AccountId,
      name: Ident,
      smtpHost: String,
      smtpPort: Option[Int],
      smtpUser: Option[String],
      smtpPassword: Option[Password],
      smtpSsl: SSLType,
      smtpCertCheck: Boolean,
      mailFrom: MailAddress,
      mailReplyTo: Option[MailAddress]
  ): OptionT[ConnectionIO, RUserEmail] =
    for {
      now  <- OptionT.liftF(Timestamp.current[ConnectionIO])
      id   <- OptionT.liftF(Ident.randomId[ConnectionIO])
      user <- OptionT(RUser.findByAccount(accId))
    } yield RUserEmail(
      id,
      user.uid,
      name,
      smtpHost,
      smtpPort,
      smtpUser,
      smtpPassword,
      smtpSsl,
      smtpCertCheck,
      mailFrom,
      mailReplyTo,
      now
    )

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

  def update(eId: Ident, v: RUserEmail): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(eId),
      commas(
        name.setTo(v.name),
        smtpHost.setTo(v.smtpHost),
        smtpPort.setTo(v.smtpPort),
        smtpUser.setTo(v.smtpUser),
        smtpPass.setTo(v.smtpPassword),
        smtpSsl.setTo(v.smtpSsl),
        smtpCertCheck.setTo(v.smtpCertCheck),
        mailFrom.setTo(v.mailFrom),
        mailReplyTo.setTo(v.mailReplyTo)
      )
    ).update.run

  def findByUser(userId: Ident): ConnectionIO[Vector[RUserEmail]] =
    selectSimple(all, table, uid.is(userId)).query[RUserEmail].to[Vector]

  private def findByAccount0(
      accId: AccountId,
      nameQ: Option[String],
      exact: Boolean
  ): Query0[RUserEmail] = {
    val mUid   = uid.prefix("m")
    val mName  = name.prefix("m")
    val uId    = RUser.Columns.uid.prefix("u")
    val uColl  = RUser.Columns.cid.prefix("u")
    val uLogin = RUser.Columns.login.prefix("u")
    val from   = table ++ fr"m INNER JOIN" ++ RUser.table ++ fr"u ON" ++ mUid.is(uId)
    val cond = Seq(uColl.is(accId.collective), uLogin.is(accId.user)) ++ (nameQ match {
      case Some(str) if exact  => Seq(mName.is(str))
      case Some(str) if !exact => Seq(mName.lowerLike(s"%${str.toLowerCase}%"))
      case None                => Seq.empty
    })

    (selectSimple(all.map(_.prefix("m")), from, and(cond)) ++ orderBy(mName.f))
      .query[RUserEmail]
  }

  def findByAccount(
      accId: AccountId,
      nameQ: Option[String]
  ): ConnectionIO[Vector[RUserEmail]] =
    findByAccount0(accId, nameQ, false).to[Vector]

  def getByName(accId: AccountId, name: Ident): ConnectionIO[Option[RUserEmail]] =
    findByAccount0(accId, Some(name.id), true).option

  def delete(accId: AccountId, connName: Ident): ConnectionIO[Int] = {
    val uId    = RUser.Columns.uid
    val uColl  = RUser.Columns.cid
    val uLogin = RUser.Columns.login
    val cond   = Seq(uColl.is(accId.collective), uLogin.is(accId.user))

    deleteFrom(
      table,
      fr"uid in (" ++ selectSimple(Seq(uId), RUser.table, and(cond)) ++ fr") AND" ++ name
        .is(
          connName
        )
    ).update.run
  }

  def exists(accId: AccountId, name: Ident): ConnectionIO[Boolean] =
    getByName(accId, name).map(_.isDefined)

  def exists(userId: Ident, connName: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, and(uid.is(userId), name.is(connName)))
      .query[Int]
      .unique
      .map(_ > 0)
}
