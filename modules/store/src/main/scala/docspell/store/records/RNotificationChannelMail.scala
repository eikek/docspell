/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import emil.MailAddress

final case class RNotificationChannelMail(
    id: Ident,
    uid: Ident,
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
    val connection = Column[Ident]("conn_id", this)
    val recipients = Column[List[MailAddress]]("recipients", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, uid, connection, recipients, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RNotificationChannelMail): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.uid},${r.connection},${r.recipients},${r.created}"
    )

  def update(r: RNotificationChannelMail): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.connection.setTo(r.connection),
        T.recipients.setTo(r.recipients.toList)
      )
    )

  def getById(id: Ident): ConnectionIO[Option[RNotificationChannelMail]] =
    run(select(T.all), from(T), T.id === id).query[RNotificationChannelMail].option

  def getByAccount(account: AccountId): ConnectionIO[Vector[RNotificationChannelMail]] = {
    val user = RUser.as("u")
    val gotify = as("c")
    Select(
      select(gotify.all),
      from(gotify).innerJoin(user, user.uid === gotify.uid),
      user.cid === account.collective && user.login === account.user
    ).build.query[RNotificationChannelMail].to[Vector]
  }

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByAccount(id: Ident, account: AccountId): ConnectionIO[Int] = {
    val u = RUser.as("u")
    DML.delete(
      T,
      T.id === id && T.uid.in(Select(select(u.uid), from(u), u.isAccount(account)))
    )
  }
}
