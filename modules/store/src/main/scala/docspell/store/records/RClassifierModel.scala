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

final case class RClassifierModel(
    id: Ident,
    cid: CollectiveId,
    name: String,
    fileId: FileKey,
    created: Timestamp
) {}

object RClassifierModel {

  def createNew[F[_]: Sync](
      cid: CollectiveId,
      name: String,
      fileId: FileKey
  ): F[RClassifierModel] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RClassifierModel(id, cid, name, fileId, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "classifier_model"

    val id = Column[Ident]("id", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val name = Column[String]("name", this)
    val fileId = Column[FileKey]("file_id", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, cid, name, fileId, created)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val T = Table(None)

  def insert(v: RClassifierModel): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.cid},${v.name},${v.fileId},${v.created}"
    )

  def updateFile(coll: CollectiveId, name: String, fid: FileKey): ConnectionIO[Int] =
    for {
      now <- Timestamp.current[ConnectionIO]
      n <- DML.update(
        T,
        T.cid === coll && T.name === name,
        DML.set(T.fileId.setTo(fid), T.created.setTo(now))
      )
      k <-
        if (n == 0) createNew[ConnectionIO](coll, name, fid).flatMap(insert)
        else 0.pure[ConnectionIO]
    } yield n + k

  def deleteById(id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === id)

  def deleteAll(ids: List[Ident]): ConnectionIO[Int] =
    NonEmptyList.fromList(ids) match {
      case Some(nel) =>
        DML.delete(T, T.id.in(nel))
      case None =>
        0.pure[ConnectionIO]
    }

  def findByName(
      cid: CollectiveId,
      name: String
  ): ConnectionIO[Option[RClassifierModel]] =
    Select(select(T.all), from(T), T.cid === cid && T.name === name).build
      .query[RClassifierModel]
      .option

  def findAllByName(
      cid: CollectiveId,
      names: NonEmptyList[String]
  ): ConnectionIO[List[RClassifierModel]] =
    Select(select(T.all), from(T), T.cid === cid && T.name.in(names)).build
      .query[RClassifierModel]
      .to[List]

  def findAllByQuery(
      cid: CollectiveId,
      nameQuery: String
  ): ConnectionIO[List[RClassifierModel]] =
    Select(select(T.all), from(T), T.cid === cid && T.name.like(nameQuery)).build
      .query[RClassifierModel]
      .to[List]
}
