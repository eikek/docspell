/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import emil.MailAddress

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

  final case class Table(alias: Option[String]) extends TableDef {

    val tableName = "sentmail"

    val id         = Column[Ident]("id", this)
    val uid        = Column[Ident]("uid", this)
    val messageId  = Column[String]("message_id", this)
    val sender     = Column[MailAddress]("sender", this)
    val connName   = Column[Ident]("conn_name", this)
    val subject    = Column[String]("subject", this)
    val recipients = Column[List[MailAddress]]("recipients", this)
    val body       = Column[String]("body", this)
    val created    = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](
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

  private val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RSentMail): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${v.id},${v.uid},${v.messageId},${v.sender},${v.connName},${v.subject},${v.recipients},${v.body},${v.created}"
    )

  def findByUser(userId: Ident): Stream[ConnectionIO, RSentMail] =
    run(select(T.all), from(T), T.uid === userId).query[RSentMail].stream

  def delete(mailId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === mailId)

  def deleteByItem(item: Ident): ConnectionIO[Int] =
    for {
      list <- RSentMailItem.findSentMailIdsByItem(item)
      n1   <- RSentMailItem.deleteAllByItem(item)
      n0 <- NonEmptyList.fromList(list.toList) match {
        case Some(nel) => DML.delete(T, T.id.in(nel))
        case None      => 0.pure[ConnectionIO]
      }
    } yield n0 + n1

}
