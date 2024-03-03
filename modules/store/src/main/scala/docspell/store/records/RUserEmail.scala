/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList, OptionT}
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

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
      id <- Ident.randomId[F]
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

  def fromUser(
      userId: Ident,
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
      now <- OptionT.liftF(Timestamp.current[ConnectionIO])
      id <- OptionT.liftF(Ident.randomId[ConnectionIO])
    } yield RUserEmail(
      id,
      userId,
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
  final case class Table(alias: Option[String]) extends TableDef {

    val tableName = "useremail"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val name = Column[Ident]("name", this)
    val smtpHost = Column[String]("smtp_host", this)
    val smtpPort = Column[Int]("smtp_port", this)
    val smtpUser = Column[String]("smtp_user", this)
    val smtpPass = Column[Password]("smtp_password", this)
    val smtpSsl = Column[SSLType]("smtp_ssl", this)
    val smtpCertCheck = Column[Boolean]("smtp_certcheck", this)
    val mailFrom = Column[MailAddress]("mail_from", this)
    val mailReplyTo = Column[MailAddress]("mail_replyto", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](
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

  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RUserEmail): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      sql"${v.id},${v.uid},${v.name},${v.smtpHost},${v.smtpPort},${v.smtpUser},${v.smtpPassword},${v.smtpSsl},${v.smtpCertCheck},${v.mailFrom},${v.mailReplyTo},${v.created}"
    )
  }

  def update(eId: Ident, v: RUserEmail): ConnectionIO[Int] = {
    val t = Table(None)
    DML.update(
      t,
      t.id === eId,
      DML.set(
        t.name.setTo(v.name),
        t.smtpHost.setTo(v.smtpHost),
        t.smtpPort.setTo(v.smtpPort),
        t.smtpUser.setTo(v.smtpUser),
        t.smtpPass.setTo(v.smtpPassword),
        t.smtpSsl.setTo(v.smtpSsl),
        t.smtpCertCheck.setTo(v.smtpCertCheck),
        t.mailFrom.setTo(v.mailFrom),
        t.mailReplyTo.setTo(v.mailReplyTo)
      )
    )
  }

  def findByUser(userId: Ident): ConnectionIO[Vector[RUserEmail]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.uid === userId).query[RUserEmail].to[Vector]
  }

  private def findByAccount0(
      userId: Ident,
      nameQ: Option[String],
      exact: Boolean
  ): Query0[RUserEmail] = {
    val email = as("m")

    val nameFilter = nameQ.map(s =>
      if (exact) email.name ==== s else email.name.likes(s"%${s.toLowerCase}%")
    )

    val sql = Select(
      select(email.all),
      from(email),
      email.uid === userId &&? nameFilter
    ).orderBy(email.name)

    sql.build.query[RUserEmail]
  }

  def findByAccount(
      userId: Ident,
      nameQ: Option[String]
  ): ConnectionIO[Vector[RUserEmail]] =
    findByAccount0(userId, nameQ, exact = false).to[Vector]

  def getByName(userId: Ident, name: Ident): ConnectionIO[Option[RUserEmail]] =
    findByAccount0(userId, Some(name.id), exact = true).option

  def getById(id: Ident): ConnectionIO[Option[RUserEmail]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.id === id).query[RUserEmail].option
  }

  def delete(userId: Ident, connName: Ident): ConnectionIO[Int] = {
    val t = Table(None)
    DML.delete(t, t.uid === userId && t.name === connName)
  }

  def exists(userId: Ident, connName: Ident): ConnectionIO[Boolean] = {
    val t = Table(None)
    run(select(count(t.id)), from(t), t.uid === userId && t.name === connName)
      .query[Int]
      .unique
      .map(_ > 0)
  }
}
