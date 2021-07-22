/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList, OptionT}
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import com.github.eikek.calev._
import doobie._
import doobie.implicits._

case class RClassifierSetting(
    cid: Ident,
    schedule: CalEvent,
    itemCount: Int,
    created: Timestamp,
    categoryList: List[String],
    listType: ListType
) {

  def autoTagEnabled: Boolean =
    listType match {
      case ListType.Blacklist =>
        true
      case ListType.Whitelist =>
        categoryList.nonEmpty
    }
}

object RClassifierSetting {
  // the categoryList is stored as a json array
  implicit val stringListMeta: Meta[List[String]] =
    jsonMeta[List[String]]

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "classifier_setting"

    val cid        = Column[Ident]("cid", this)
    val schedule   = Column[CalEvent]("schedule", this)
    val itemCount  = Column[Int]("item_count", this)
    val created    = Column[Timestamp]("created", this)
    val categories = Column[List[String]]("categories", this)
    val listType   = Column[ListType]("category_list_type", this)
    val all = NonEmptyList
      .of[Column[_]](cid, schedule, itemCount, created, categories, listType)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RClassifierSetting): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.cid},${v.schedule},${v.itemCount},${v.created},${v.categoryList},${v.listType}"
    )

  def update(v: RClassifierSetting): ConnectionIO[Int] =
    for {
      n1 <- DML.update(
        T,
        T.cid === v.cid,
        DML.set(
          T.schedule.setTo(v.schedule),
          T.itemCount.setTo(v.itemCount),
          T.categories.setTo(v.categoryList),
          T.listType.setTo(v.listType)
        )
      )
      n2 <- if (n1 <= 0) insert(v) else 0.pure[ConnectionIO]
    } yield n1 + n2

  def findById(id: Ident): ConnectionIO[Option[RClassifierSetting]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[RClassifierSetting].option
  }

  def delete(coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === coll)

  /** Finds tag categories that exist and match the classifier setting.
    * If the setting contains a black list, they are removed from the
    * existing categories. If it is a whitelist, the intersection is
    * returned.
    */
  def getActiveCategories(coll: Ident): ConnectionIO[List[String]] =
    (for {
      sett <- OptionT(findById(coll))
      cats <- OptionT.liftF(RTag.listCategories(coll))
      res = sett.listType match {
        case ListType.Blacklist =>
          cats.diff(sett.categoryList)
        case ListType.Whitelist =>
          sett.categoryList.intersect(cats)
      }
    } yield res).getOrElse(Nil)

  /** Checks the json array of tag categories and removes those that are not present anymore. */
  def fixCategoryList(coll: Ident): ConnectionIO[Int] =
    (for {
      sett <- OptionT(findById(coll))
      cats <- OptionT.liftF(RTag.listCategories(coll))
      fixed = sett.categoryList.intersect(cats)
      n <- OptionT.liftF(
        if (fixed == sett.categoryList) 0.pure[ConnectionIO]
        else DML.update(T, T.cid === coll, DML.set(T.categories.setTo(fixed)))
      )
    } yield n).getOrElse(0)

  case class Classifier(
      schedule: CalEvent,
      itemCount: Int,
      categories: List[String],
      listType: ListType
  ) {
    def enabled: Boolean =
      listType match {
        case ListType.Blacklist =>
          true
        case ListType.Whitelist =>
          categories.nonEmpty
      }

    def toRecord(coll: Ident, created: Timestamp): RClassifierSetting =
      RClassifierSetting(
        coll,
        schedule,
        itemCount,
        created,
        categories,
        listType
      )
  }
  object Classifier {
    def fromRecord(r: RClassifierSetting): Classifier =
      Classifier(r.schedule, r.itemCount, r.categoryList, r.listType)
  }

}
