/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RTagItem(tagItemId: Ident, itemId: Ident, tagId: Ident) {}

object RTagItem {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "tagitem"

    val tagItemId = Column[Ident]("tagitemid", this)
    val itemId = Column[Ident]("itemid", this)
    val tagId = Column[Ident]("tid", this)
    val all = NonEmptyList.of[Column[_]](tagItemId, itemId, tagId)
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RTagItem): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.tagItemId},${v.itemId},${v.tagId}")

  def moveTags(fromItem: Ident, toItem: Ident): ConnectionIO[Int] =
    for {
      both <- intersect(
        Select(select(T.tagId), from(T), T.itemId === fromItem).distinct,
        Select(select(T.tagId), from(T), T.itemId === toItem).distinct
      ).build
        .query[Ident]
        .to[List]
      skipIds = NonEmptyList.fromList(both)
      n <- DML.update(
        T,
        T.itemId === fromItem &&? skipIds.map(ids => T.tagId.notIn(ids)),
        DML.set(T.itemId.setTo(toItem))
      )
    } yield n

  def deleteItemTags(item: Ident): ConnectionIO[Int] =
    DML.delete(T, T.itemId === item)

  def deleteItemTags(items: NonEmptyList[Ident], cid: CollectiveId): ConnectionIO[Int] =
    DML.delete(T, T.itemId.in(RItem.filterItemsFragment(items, cid)))

  def deleteTag(tid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.tagId === tid)

  def findByItem(item: Ident): ConnectionIO[Vector[RTagItem]] =
    run(select(T.all), from(T), T.itemId === item).query[RTagItem].to[Vector]

  def findAllIn(item: Ident, tags: Seq[Ident]): ConnectionIO[Vector[RTagItem]] =
    NonEmptyList.fromList(tags.toList) match {
      case Some(nel) =>
        run(select(T.all), from(T), T.itemId === item && T.tagId.in(nel))
          .query[RTagItem]
          .to[Vector]
      case None =>
        Vector.empty.pure[ConnectionIO]
    }

  def removeAllTags(item: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    NonEmptyList.fromList(tags.toList) match {
      case None =>
        0.pure[ConnectionIO]
      case Some(nel) =>
        DML.delete(T, T.itemId === item && T.tagId.in(nel))
    }

  def setAllTags(item: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    if (tags.isEmpty) 0.pure[ConnectionIO]
    else
      for {
        entities <- tags.toList.traverse(tagId =>
          Ident.randomId[ConnectionIO].map(id => RTagItem(id, item, tagId))
        )
        n <- DML
          .insertMany(
            T,
            T.all,
            entities.map(v => fr"${v.tagItemId},${v.itemId},${v.tagId}")
          )
      } yield n

  def appendTags(item: Ident, tags: List[Ident]): ConnectionIO[Set[Ident]] =
    for {
      existing <- findByItem(item)
      toadd = tags.toSet.diff(existing.map(_.tagId).toSet)
      _ <- setAllTags(item, toadd.toSeq)
    } yield toadd

}
