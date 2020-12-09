package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._

import doobie._

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
    val ti        = RTagItem.as("ti")
    val t         = RTag.as("t")
    val join      = from(t).innerJoin(ti, t.tid === ti.tagId)
    if (cats.tail.isEmpty)
      run(select(ti.itemId), join, t.category.likes(catsLower.head))
    else
      run(select(ti.itemId), join, t.category.inLower(cats))
  }

  def itemsWithTagOrCategory(tags: List[Ident], cats: List[String]): Fragment = {
    val catsLower = cats.map(_.toLowerCase)
    val ti        = RTagItem.as("ti")
    val t         = RTag.as("t")
    val join      = from(t).innerJoin(ti, t.tid === ti.tagId)
    (NonEmptyList.fromList(tags), NonEmptyList.fromList(catsLower)) match {
      case (Some(tagNel), Some(catNel)) =>
        run(select(ti.itemId), join, t.tid.in(tagNel) || t.category.inLower(catNel))
      case (Some(tagNel), None) =>
        run(select(ti.itemId), join, t.tid.in(tagNel))
      case (None, Some(catNel)) =>
        run(select(ti.itemId), join, t.category.inLower(catNel))
      case (None, None) =>
        Fragment.empty
    }
  }
}
