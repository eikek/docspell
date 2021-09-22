/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RSentMailItem(
    id: Ident,
    itemId: Ident,
    sentMailId: Ident,
    created: Timestamp
) {}

object RSentMailItem {

  def apply[F[_]: Sync](
      itemId: Ident,
      sentmailId: Ident,
      created: Option[Timestamp] = None
  ): F[RSentMailItem] =
    for {
      id <- Ident.randomId[F]
      now <- created.map(_.pure[F]).getOrElse(Timestamp.current[F])
    } yield RSentMailItem(id, itemId, sentmailId, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "sentmailitem"

    val id = Column[Ident]("id", this)
    val itemId = Column[Ident]("item_id", this)
    val sentMailId = Column[Ident]("sentmail_id", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](
      id,
      itemId,
      sentMailId,
      created
    )
  }

  private val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RSentMailItem): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${v.id},${v.itemId},${v.sentMailId},${v.created}"
    )

  def deleteMail(mailId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.sentMailId === mailId)

  def findSentMailIdsByItem(item: Ident): ConnectionIO[Set[Ident]] =
    run(select(T.sentMailId.s), from(T), T.itemId === item).query[Ident].to[Set]

  def deleteAllByItem(item: Ident): ConnectionIO[Int] =
    DML.delete(T, T.itemId === item)

  def moveToItem(target: Ident, others: NonEmptyList[Ident]): ConnectionIO[Int] =
    DML.update(T, T.itemId.in(others), DML.set(T.itemId.setTo(target)))
}
