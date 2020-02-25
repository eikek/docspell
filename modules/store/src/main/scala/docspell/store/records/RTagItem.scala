package docspell.store.records

import cats.implicits._
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

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
}
