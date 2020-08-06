package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

/** A helper class combining information from `RTag` and `RTagItem`.
  * This is not a "record", there is no corresponding table.
  */
case class TagItemName(
    tagId: Ident,
    collective: Ident,
    name: String,
    category: Option[String],
    tagItemId: Ident,
    itemId: Ident
)

object TagItemName {

  def itemsInCategory(cats: NonEmptyList[String]): Fragment = {
    val catsLower = cats.map(_.toLowerCase)
    val tiItem    = RTagItem.Columns.itemId.prefix("ti")
    val tiTag     = RTagItem.Columns.tagId.prefix("ti")
    val tCat      = RTag.Columns.category.prefix("t")
    val tId       = RTag.Columns.tid.prefix("t")

    val from = RTag.table ++ fr"t INNER JOIN" ++
      RTagItem.table ++ fr"ti ON" ++ tiTag.is(tId)

    if (cats.tail.isEmpty)
      selectSimple(List(tiItem), from, tCat.lowerIs(catsLower.head))
    else
      selectSimple(List(tiItem), from, tCat.isLowerIn(catsLower))
  }

  def itemsWithTagOrCategory(tags: List[Ident], cats: List[String]): Fragment = {
    val catsLower = cats.map(_.toLowerCase)
    val tiItem    = RTagItem.Columns.itemId.prefix("ti")
    val tiTag     = RTagItem.Columns.tagId.prefix("ti")
    val tCat      = RTag.Columns.category.prefix("t")
    val tId       = RTag.Columns.tid.prefix("t")

    val from = RTag.table ++ fr"t INNER JOIN" ++
      RTagItem.table ++ fr"ti ON" ++ tiTag.is(tId)

    (NonEmptyList.fromList(tags), NonEmptyList.fromList(catsLower)) match {
      case (Some(tagNel), Some(catNel)) =>
        selectSimple(List(tiItem), from, or(tId.isIn(tagNel), tCat.isLowerIn(catNel)))
      case (Some(tagNel), None) =>
        selectSimple(List(tiItem), from, tId.isIn(tagNel))
      case (None, Some(catNel)) =>
        selectSimple(List(tiItem), from, tCat.isLowerIn(catNel))
      case (None, None) =>
        Fragment.empty
    }
  }
}
