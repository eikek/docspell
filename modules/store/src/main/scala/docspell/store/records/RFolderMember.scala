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

case class RFolderMember(
    id: Ident,
    folderId: Ident,
    userId: Ident,
    created: Timestamp
)

object RFolderMember {

  def newMember[F[_]: Sync](folder: Ident, user: Ident): F[RFolderMember] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RFolderMember(nId, folder, user, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "folder_member"

    val id      = Column[Ident]("id", this)
    val folder  = Column[Ident]("folder_id", this)
    val user    = Column[Ident]("user_id", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, folder, user, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(value: RFolderMember): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${value.id},${value.folderId},${value.userId},${value.created}"
    )

  def findByUserId(userId: Ident, folderId: Ident): ConnectionIO[Option[RFolderMember]] =
    run(select(T.all), from(T), T.folder === folderId && T.user === userId)
      .query[RFolderMember]
      .option

  def delete(userId: Ident, folderId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.folder === folderId && T.user === userId)

  def deleteAll(folderId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.folder === folderId)

  def deleteMemberships(userId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.user === userId)
}
