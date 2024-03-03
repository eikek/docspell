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
    imapOAuth2: Boolean,
    created: Timestamp
) {

  def toMailConfig: MailConfig = {
    val port = imapPort.map(p => s":$p").getOrElse("")
    MailConfig(
      s"imap://$imapHost$port",
      imapUser.getOrElse(""),
      imapPassword.map(_.pass).getOrElse(""),
      imapSsl,
      imapOAuth2,
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
      imapCertCheck: Boolean,
      imapOAuth2: Boolean
  ): F[RUserImap] =
    for {
      now <- Timestamp.current[F]
      id <- Ident.randomId[F]
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
      imapOAuth2,
      now
    )

  def fromUser(
      userId: Ident,
      name: Ident,
      imapHost: String,
      imapPort: Option[Int],
      imapUser: Option[String],
      imapPassword: Option[Password],
      imapSsl: SSLType,
      imapCertCheck: Boolean,
      imapOAuth2: Boolean
  ): OptionT[ConnectionIO, RUserImap] =
    for {
      now <- OptionT.liftF(Timestamp.current[ConnectionIO])
      id <- OptionT.liftF(Ident.randomId[ConnectionIO])
    } yield RUserImap(
      id,
      userId,
      name,
      imapHost,
      imapPort,
      imapUser,
      imapPassword,
      imapSsl,
      imapCertCheck,
      imapOAuth2,
      now
    )

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "userimap"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val name = Column[Ident]("name", this)
    val imapHost = Column[String]("imap_host", this)
    val imapPort = Column[Int]("imap_port", this)
    val imapUser = Column[String]("imap_user", this)
    val imapPass = Column[Password]("imap_password", this)
    val imapSsl = Column[SSLType]("imap_ssl", this)
    val imapCertCheck = Column[Boolean]("imap_certcheck", this)
    val imapOAuth2 = Column[Boolean]("imap_oauth2", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](
      id,
      uid,
      name,
      imapHost,
      imapPort,
      imapUser,
      imapPass,
      imapSsl,
      imapCertCheck,
      imapOAuth2,
      created
    )
  }

  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RUserImap): ConnectionIO[Int] = {
    val t = Table(None)
    DML
      .insert(
        t,
        t.all,
        sql"${v.id},${v.uid},${v.name},${v.imapHost},${v.imapPort},${v.imapUser},${v.imapPassword},${v.imapSsl},${v.imapCertCheck},${v.imapOAuth2},${v.created}"
      )
  }

  def update(eId: Ident, v: RUserImap): ConnectionIO[Int] = {
    val t = Table(None)
    DML.update(
      t,
      t.id === eId,
      DML.set(
        t.name.setTo(v.name),
        t.imapHost.setTo(v.imapHost),
        t.imapPort.setTo(v.imapPort),
        t.imapUser.setTo(v.imapUser),
        t.imapPass.setTo(v.imapPassword),
        t.imapSsl.setTo(v.imapSsl),
        t.imapCertCheck.setTo(v.imapCertCheck),
        t.imapOAuth2.setTo(v.imapOAuth2)
      )
    )
  }

  def findByUser(userId: Ident): ConnectionIO[Vector[RUserImap]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.uid === userId).query[RUserImap].to[Vector]
  }

  private def findByAccount0(
      userId: Ident,
      nameQ: Option[String],
      exact: Boolean
  ): Query0[RUserImap] = {
    val m = RUserImap.as("m")

    val nameFilter =
      nameQ.map { str =>
        if (exact) m.name ==== str
        else m.name.likes(s"%${str.toLowerCase}%")
      }

    val sql = Select(
      select(m.all),
      from(m),
      m.uid === userId &&? nameFilter
    ).orderBy(m.name).build

    sql.query[RUserImap]
  }

  def findByAccount(
      userId: Ident,
      nameQ: Option[String]
  ): ConnectionIO[Vector[RUserImap]] =
    findByAccount0(userId, nameQ, exact = false).to[Vector]

  def getByName(
      userId: Ident,
      name: Ident
  ): ConnectionIO[Option[RUserImap]] =
    findByAccount0(userId, Some(name.id), exact = true).option

  def delete(
      userId: Ident,
      connName: Ident
  ): ConnectionIO[Int] = {
    val t = Table(None)

    DML.delete(
      t,
      t.uid === userId && t.name === connName
    )
  }

  def exists(userId: Ident, connName: Ident): ConnectionIO[Boolean] = {
    val t = Table(None)
    run(select(count(t.id)), from(t), t.uid === userId && t.name === connName)
      .query[Int]
      .unique
      .map(_ > 0)
  }
}
