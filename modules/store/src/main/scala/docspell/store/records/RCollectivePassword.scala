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

final case class RCollectivePassword(
    id: Ident,
    cid: CollectiveId,
    password: Password,
    created: Timestamp
) {}

object RCollectivePassword {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName: String = "collective_password"

    val id = Column[Ident]("id", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val password = Column[Password]("pass", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(id, cid, password, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def createNew[F[_]: Sync](cid: CollectiveId, pw: Password): F[RCollectivePassword] =
    for {
      id <- Ident.randomId[F]
      time <- Timestamp.current[F]
    } yield RCollectivePassword(id, cid, pw, time)

  def insert(v: RCollectivePassword): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id}, ${v.cid},${v.password},${v.created}"
    )

  def upsert(v: RCollectivePassword): ConnectionIO[Int] =
    for {
      k <- deleteByPassword(v.cid, v.password)
      n <- insert(v)
    } yield n + k

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteByPassword(cid: CollectiveId, pw: Password): ConnectionIO[Int] =
    DML.delete(T, T.password === pw && T.cid === cid)

  def findAll(cid: CollectiveId): ConnectionIO[List[RCollectivePassword]] =
    Select(select(T.all), from(T), T.cid === cid).build
      .query[RCollectivePassword]
      .to[List]

  def replaceAll(cid: CollectiveId, pws: List[Password]): ConnectionIO[Int] =
    for {
      k <- DML.delete(T, T.cid === cid)
      pw <- pws.traverse(p => createNew[ConnectionIO](cid, p))
      n <-
        if (pws.isEmpty) 0.pure[ConnectionIO]
        else
          DML.insertMany(
            T,
            T.all,
            pw.map(p => fr"${p.id},${p.cid},${p.password},${p.created}")
          )
    } yield k + n
}
