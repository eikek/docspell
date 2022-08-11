/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.notification.api.ChannelType
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import emil.MailAddress

final case class RNotificationChannelMail(
    id: Ident,
    uid: Ident,
    name: Option[String],
    connection: Ident,
    recipients: List[MailAddress],
    created: Timestamp
) {
  def vary: RNotificationChannel =
    RNotificationChannel.Email(this)
}

object RNotificationChannelMail {
  final case class Table(alias: Option[String]) extends TableDef {

    val tableName = "notification_channel_mail"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val name = Column[String]("name", this)
    val connection = Column[Ident]("conn_id", this)
    val recipients = Column[List[MailAddress]]("recipients", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, uid, name, connection, recipients, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RNotificationChannelMail): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.uid},${r.name},${r.connection},${r.recipients},${r.created}"
    )

  def update(r: RNotificationChannelMail): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.connection.setTo(r.connection),
        T.recipients.setTo(r.recipients.toList),
        T.name.setTo(r.name)
      )
    )

  def getById(userId: Ident)(id: Ident): ConnectionIO[Option[RNotificationChannelMail]] =
    run(select(T.all), from(T), T.id === id && T.uid === userId)
      .query[RNotificationChannelMail]
      .option

  def getByAccount(userId: Ident): ConnectionIO[Vector[RNotificationChannelMail]] = {
    val mail = as("c")
    Select(
      select(mail.all),
      from(mail),
      mail.uid === userId
    ).build.query[RNotificationChannelMail].to[Vector]
  }

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByAccount(id: Ident, userId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id && T.uid === userId)

  def findRefs(ids: NonEmptyList[Ident]): Select =
    Select(
      select(T.id.s, const(ChannelType.Mail.name), T.name.s),
      from(T),
      T.id.in(ids)
    )
}
