/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.syntax.all._

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import docspell.store.AddResult

final case class RQueryBookmark(
    id: Ident,
    name: String,
    label: Option[String],
    userId: Option[Ident],
    cid: Ident,
    query: ItemQuery,
    created: Timestamp
) {
  def isPersonal: Boolean =
    userId.isDefined

  def asGlobal: RQueryBookmark =
    copy(userId = None)

  def asPersonal(userId: Ident): RQueryBookmark =
    copy(userId = userId.some)
}

object RQueryBookmark {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "query_bookmark";

    val id = Column[Ident]("id", this)
    val name = Column[String]("name", this)
    val label = Column[String]("label", this)
    val userId = Column[Ident]("user_id", this)
    val cid = Column[Ident]("cid", this)
    val query = Column[ItemQuery]("query", this)
    val created = Column[Timestamp]("created", this)

    val internUserId = Column[String]("__user_id", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, name, label, userId, cid, query, created)
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def createNew(
      account: AccountId,
      name: String,
      label: Option[String],
      query: ItemQuery,
      personal: Boolean
  ): ConnectionIO[RQueryBookmark] =
    for {
      userId <- RUser.getIdByAccount(account)
      curTime <- Timestamp.current[ConnectionIO]
      id <- Ident.randomId[ConnectionIO]
    } yield RQueryBookmark(
      id,
      name,
      label,
      if (personal) userId.some else None,
      account.collective,
      query,
      curTime
    )

  def insert(r: RQueryBookmark): ConnectionIO[Int] = {
    val userIdDummy = r.userId.getOrElse(Ident.unsafe("-"))
    DML.insert(
      T,
      T.all.append(T.internUserId),
      sql"${r.id},${r.name},${r.label},${r.userId},${r.cid},${r.query},${r.created},$userIdDummy"
    )
  }

  def update(r: RQueryBookmark): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id,
      DML.set(
        T.name.setTo(r.name),
        T.label.setTo(r.label),
        T.query.setTo(r.query)
      )
    )

  def deleteById(cid: Ident, id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id && T.cid === cid)

  def nameExists(account: AccountId, name: String): ConnectionIO[Boolean] = {
    val user = RUser.as("u")
    val bm = RQueryBookmark.as("bm")

    val users = Select(
      user.uid.s,
      from(user),
      user.cid === account.collective && user.login === account.user
    )
    Select(
      select(count(bm.id)),
      from(bm),
      bm.name === name && bm.cid === account.collective && (bm.userId.isNull || bm.userId
        .in(users))
    ).build.query[Int].unique.map(_ > 0)
  }

  // impl note: store.add doesn't work, because it checks for duplicate
  // after trying to insert the check is necessary because a name
  // should be unique across personal *and* collective bookmarks
  def insertIfNotExists(
      account: AccountId,
      r: ConnectionIO[RQueryBookmark]
  ): ConnectionIO[AddResult] =
    for {
      bm <- r
      res <-
        nameExists(account, bm.name).flatMap {
          case true =>
            AddResult
              .entityExists(s"A bookmark '${bm.name}' already exists.")
              .pure[ConnectionIO]
          case false => insert(bm).attempt.map(AddResult.fromUpdate)
        }
    } yield res

  def allForUser(account: AccountId): ConnectionIO[Vector[RQueryBookmark]] = {
    val user = RUser.as("u")
    val bm = RQueryBookmark.as("bm")

    val users = Select(
      user.uid.s,
      from(user),
      user.cid === account.collective && user.login === account.user
    )
    Select(
      select(bm.all),
      from(bm),
      bm.cid === account.collective && (bm.userId.isNull || bm.userId.in(users))
    ).build.query[RQueryBookmark].to[Vector]
  }
}
