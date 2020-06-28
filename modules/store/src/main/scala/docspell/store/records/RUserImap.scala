package docspell.store.records

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._
import emil.{MailConfig, SSLType}

case class RUserImap(
    id: Ident,
    uid: Ident,
    name: Ident,
    imapHost: String,
    imapPort: Option[Int],
    imapUser: Option[String],
    imapPassword: Option[Password],
    imapSsl: SSLType,
    imapCertCheck: Boolean,
    created: Timestamp
) {

  def toMailConfig: MailConfig = {
    val port = imapPort.map(p => s":$p").getOrElse("")
    MailConfig(
      s"imap://$imapHost$port",
      imapUser.getOrElse(""),
      imapPassword.map(_.pass).getOrElse(""),
      imapSsl,
      !imapCertCheck
    )
  }
}

object RUserImap {

  def apply[F[_]: Sync](
      uid: Ident,
      name: Ident,
      imapHost: String,
      imapPort: Option[Int],
      imapUser: Option[String],
      imapPassword: Option[Password],
      imapSsl: SSLType,
      imapCertCheck: Boolean
  ): F[RUserImap] =
    for {
      now <- Timestamp.current[F]
      id  <- Ident.randomId[F]
    } yield RUserImap(
      id,
      uid,
      name,
      imapHost,
      imapPort,
      imapUser,
      imapPassword,
      imapSsl,
      imapCertCheck,
      now
    )

  def fromAccount(
      accId: AccountId,
      name: Ident,
      imapHost: String,
      imapPort: Option[Int],
      imapUser: Option[String],
      imapPassword: Option[Password],
      imapSsl: SSLType,
      imapCertCheck: Boolean
  ): OptionT[ConnectionIO, RUserImap] =
    for {
      now  <- OptionT.liftF(Timestamp.current[ConnectionIO])
      id   <- OptionT.liftF(Ident.randomId[ConnectionIO])
      user <- OptionT(RUser.findByAccount(accId))
    } yield RUserImap(
      id,
      user.uid,
      name,
      imapHost,
      imapPort,
      imapUser,
      imapPassword,
      imapSsl,
      imapCertCheck,
      now
    )

  val table = fr"userimap"

  object Columns {
    val id            = Column("id")
    val uid           = Column("uid")
    val name          = Column("name")
    val imapHost      = Column("imap_host")
    val imapPort      = Column("imap_port")
    val imapUser      = Column("imap_user")
    val imapPass      = Column("imap_password")
    val imapSsl       = Column("imap_ssl")
    val imapCertCheck = Column("imap_certcheck")
    val created       = Column("created")

    val all = List(
      id,
      uid,
      name,
      imapHost,
      imapPort,
      imapUser,
      imapPass,
      imapSsl,
      imapCertCheck,
      created
    )
  }

  import Columns._

  def insert(v: RUserImap): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      sql"${v.id},${v.uid},${v.name},${v.imapHost},${v.imapPort},${v.imapUser},${v.imapPassword},${v.imapSsl},${v.imapCertCheck},${v.created}"
    ).update.run

  def update(eId: Ident, v: RUserImap): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(eId),
      commas(
        name.setTo(v.name),
        imapHost.setTo(v.imapHost),
        imapPort.setTo(v.imapPort),
        imapUser.setTo(v.imapUser),
        imapPass.setTo(v.imapPassword),
        imapSsl.setTo(v.imapSsl),
        imapCertCheck.setTo(v.imapCertCheck)
      )
    ).update.run

  def findByUser(userId: Ident): ConnectionIO[Vector[RUserImap]] =
    selectSimple(all, table, uid.is(userId)).query[RUserImap].to[Vector]

  private def findByAccount0(
      accId: AccountId,
      nameQ: Option[String],
      exact: Boolean
  ): Query0[RUserImap] = {
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
      .query[RUserImap]
  }

  def findByAccount(
      accId: AccountId,
      nameQ: Option[String]
  ): ConnectionIO[Vector[RUserImap]] =
    findByAccount0(accId, nameQ, false).to[Vector]

  def getByName(accId: AccountId, name: Ident): ConnectionIO[Option[RUserImap]] =
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
