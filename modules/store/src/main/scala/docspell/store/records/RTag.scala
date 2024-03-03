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

case class RTag(
    tagId: Ident,
    collective: CollectiveId,
    name: String,
    category: Option[String],
    created: Timestamp
) {}

object RTag {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "tag"

    val tid = Column[Ident]("tid", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val name = Column[String]("name", this)
    val category = Column[String]("category", this)
    val created = Column[Timestamp]("created", this)
    val all = NonEmptyList.of[Column[_]](tid, cid, name, category, created)
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RTag): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.tagId},${v.collective},${v.name},${v.category},${v.created}"
    )

  def update(v: RTag): ConnectionIO[Int] =
    DML.update(
      T,
      T.tid === v.tagId && T.cid === v.collective,
      DML.set(
        T.cid.setTo(v.collective),
        T.name.setTo(v.name),
        T.category.setTo(v.category)
      )
    )

  def findById(id: Ident): ConnectionIO[Option[RTag]] = {
    val sql = run(select(T.all), from(T), T.tid === id)
    sql.query[RTag].option
  }

  def findByIdAndCollective(id: Ident, coll: CollectiveId): ConnectionIO[Option[RTag]] = {
    val sql = run(select(T.all), from(T), T.tid === id && T.cid === coll)
    sql.query[RTag].option
  }

  def existsByName(tag: RTag): ConnectionIO[Boolean] = {
    val sql =
      run(select(count(T.tid)), from(T), T.cid === tag.collective && T.name === tag.name)
    sql.query[Int].unique.map(_ > 0)
  }

  def findAll(
      coll: CollectiveId,
      query: Option[String],
      order: Table => NonEmptyList[OrderBy]
  ): ConnectionIO[Vector[RTag]] = {
    val nameFilter =
      query.map(_.toLowerCase).map(s => T.name.like(s"%$s%") || T.category.like(s"%$s%"))
    val sql =
      Select(select(T.all), from(T), T.cid === coll &&? nameFilter).orderBy(order(T))
    sql.build.query[RTag].to[Vector]
  }

  def findAllById(ids: List[Ident]): ConnectionIO[Vector[RTag]] =
    NonEmptyList.fromList(ids) match {
      case Some(nel) =>
        run(select(T.all), from(T), T.tid.in(nel))
          .query[RTag]
          .to[Vector]
      case None =>
        Vector.empty.pure[ConnectionIO]
    }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RTag]] = {
    val ti = RTagItem.as("i")
    val t = RTag.as("t")
    val sql =
      Select(
        select(t.all),
        from(t).innerJoin(ti, ti.tagId === t.tid),
        ti.itemId === itemId
      ).orderBy(t.name.asc)
    sql.build.query[RTag].to[Vector]
  }

  def findBySource(source: Ident): ConnectionIO[Vector[RTag]] = {
    val s = RTagSource.as("s")
    val t = RTag.as("t")
    val sql =
      Select(
        select(t.all),
        from(t).innerJoin(s, s.tagId === t.tid),
        s.sourceId === source
      ).orderBy(t.name.asc)
    sql.build.query[RTag].to[Vector]
  }

  def findAllByNameOrId(
      nameOrIds: List[String],
      coll: CollectiveId
  ): ConnectionIO[Vector[RTag]] = {
    val idList =
      NonEmptyList.fromList(nameOrIds.flatMap(s => Ident.fromString(s).toOption))
    val nameList = NonEmptyList.fromList(nameOrIds.map(_.toLowerCase))
    (idList, nameList) match {
      case (Some(ids), _) =>
        val cond =
          T.cid === coll && (T.tid.in(ids) ||? nameList.map(names =>
            T.name.inLower(names)
          ))
        run(select(T.all), from(T), cond).query[RTag].to[Vector]
      case (_, Some(names)) =>
        val cond =
          T.cid === coll && (T.name.inLower(names) ||? idList.map(ids => T.tid.in(ids)))
        run(select(T.all), from(T), cond).query[RTag].to[Vector]
      case (None, None) =>
        Vector.empty.pure[ConnectionIO]
    }
  }

  def findOthers(
      coll: CollectiveId,
      excludeTags: List[Ident]
  ): ConnectionIO[List[RTag]] = {
    val excl =
      NonEmptyList
        .fromList(excludeTags)
        .map(nel => T.tid.notIn(nel))

    Select(
      select(T.all),
      from(T),
      T.cid === coll &&? excl
    ).orderBy(T.name.asc).build.query[RTag].to[List]
  }

  def listCategories(coll: CollectiveId): ConnectionIO[List[String]] =
    Select(
      T.category.s,
      from(T),
      T.cid === coll && T.category.isNotNull
    ).distinct.build.query[String].to[List]

  def delete(tagId: Ident, coll: CollectiveId): ConnectionIO[Int] =
    DML.delete(T, T.tid === tagId && T.cid === coll)

  def sort(tags: List[RTag]): List[RTag] =
    tags match {
      case Nil => tags
      case _ =>
        val byCat = tags
          .groupBy(_.category)
          .view
          .mapValues(_.sortBy(_.name))
          .toList
          .sortBy(_._1)

        byCat match {
          case (None, tagsByCat) :: rest =>
            rest.flatMap(_._2) ++ tagsByCat
          case _ =>
            byCat.flatMap(_._2)
        }
    }
}
