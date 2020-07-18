package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RTagItem(tagItemId: Ident, itemId: Ident, tagId: Ident) {}

object RTagItem {

  val table = fr"tagitem"

  object Columns {
    val tagItemId = Column("tagitemid")
    val itemId    = Column("itemid")
    val tagId     = Column("tid")
    val all       = List(tagItemId, itemId, tagId)
  }
  import Columns._

  def insert(v: RTagItem): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.tagItemId},${v.itemId},${v.tagId}").update.run

  def deleteItemTags(item: Ident): ConnectionIO[Int] =
    deleteFrom(table, itemId.is(item)).update.run

  def deleteTag(tid: Ident): ConnectionIO[Int] =
    deleteFrom(table, tagId.is(tid)).update.run

  def insertItemTags(item: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    for {
      tagValues <- tags.toList.traverse(id =>
        Ident.randomId[ConnectionIO].map(rid => RTagItem(rid, item, id))
      )
      tagFrag = tagValues.map(v => fr"${v.tagItemId},${v.itemId},${v.tagId}")
      ins <- insertRows(table, all, tagFrag).update.run
    } yield ins

  def findByItem(item: Ident): ConnectionIO[Vector[RTagItem]] =
    selectSimple(all, table, itemId.is(item)).query[RTagItem].to[Vector]

  def findAllIn(item: Ident, tags: Seq[Ident]): ConnectionIO[Vector[RTagItem]] =
    NonEmptyList.fromList(tags.toList) match {
      case Some(nel) =>
        selectSimple(all, table, and(itemId.is(item), tagId.isIn(nel)))
          .query[RTagItem]
          .to[Vector]
      case None =>
        Vector.empty.pure[ConnectionIO]
    }

  def setAllTags(item: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    if (tags.isEmpty) 0.pure[ConnectionIO]
    else
      for {
        entities <- tags.toList.traverse(tagId =>
          Ident.randomId[ConnectionIO].map(id => RTagItem(id, item, tagId))
        )
        n <- insertRows(
          table,
          all,
          entities.map(v => fr"${v.tagItemId},${v.itemId},${v.tagId}")
        ).update.run
      } yield n
}
