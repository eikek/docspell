/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb.{Condition, Select}

/** A helper class combining information from `RTag` and `RTagItem`. This is not a
  * "record", there is no corresponding table.
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
  private val ti = RTagItem.as("ti")
  private val t  = RTag.as("t")

  private val taggedItems =
    from(t).innerJoin(ti, t.tid === ti.tagId)

  private def orTags(tags: NonEmptyList[Ident]): Condition =
    ti.tagId.in(tags)

  private def orCategory(cats: NonEmptyList[String]): Condition =
    t.category.inLower(cats)

  def itemsInEitherCategory(cats: NonEmptyList[String]): Select =
    Select(ti.itemId.s, taggedItems, orCategory(cats)).distinct

  def itemsInAllCategories(cats: NonEmptyList[String]): Select =
    intersect(
      cats.map(cat => Select(ti.itemId.s, taggedItems, t.category.lowerEq(cat)).distinct)
    )

  def itemsWithEitherTag(tags: NonEmptyList[Ident]): Select =
    Select(ti.itemId.s, from(ti), orTags(tags)).distinct

  def itemsWithEitherTagNameOrIds(tags: NonEmptyList[String]): Select =
    Select(
      ti.itemId.s,
      from(ti).innerJoin(t, t.tid === ti.tagId),
      ti.tagId.cast[String].in(tags) || t.name.inLower(tags.map(_.toLowerCase))
    ).distinct

  def itemsWithAllTags(tags: NonEmptyList[Ident]): Select =
    intersect(tags.map(tid => Select(ti.itemId.s, from(ti), ti.tagId === tid).distinct))

  def itemsWithAllTagNameOrIds(tags: NonEmptyList[String]): Select =
    intersect(
      tags.map(tag =>
        Select(
          ti.itemId.s,
          from(ti).innerJoin(t, t.tid === ti.tagId),
          ti.tagId ==== tag || t.name.lowerEq(tag.toLowerCase)
        ).distinct
      )
    )

  def itemsWithEitherTagOrCategory(
      tags: NonEmptyList[Ident],
      cats: NonEmptyList[String]
  ): Select =
    Select(ti.itemId.s, taggedItems, orTags(tags) || orCategory(cats))

  def itemsWithAllTagAndCategory(
      tags: NonEmptyList[Ident],
      cats: NonEmptyList[String]
  ): Select =
    Select(
      ti.itemId.s,
      from(ti),
      ti.itemId.in(itemsWithAllTags(tags)) &&
        ti.itemId.in(itemsInAllCategories(cats))
    )

  def itemsWithEitherTagOrCategory(
      tags: List[Ident],
      cats: List[String]
  ): Option[Select] = {
    val catsLower = cats.map(_.toLowerCase)
    (NonEmptyList.fromList(tags), NonEmptyList.fromList(catsLower)) match {
      case (Some(tagNel), Some(catNel)) =>
        Some(itemsWithEitherTagOrCategory(tagNel, catNel))
      case (Some(tagNel), None) =>
        Some(itemsWithEitherTag(tagNel))
      case (None, Some(catNel)) =>
        Some(itemsInEitherCategory(catNel))
      case (None, None) =>
        None
    }
  }

  def itemsWithAllTagAndCategory(
      tags: List[Ident],
      cats: List[String]
  ): Option[Select] = {
    val catsLower = cats.map(_.toLowerCase)
    (NonEmptyList.fromList(tags), NonEmptyList.fromList(catsLower)) match {
      case (Some(tagNel), Some(catNel)) =>
        Some(itemsWithAllTagAndCategory(tagNel, catNel))
      case (Some(tagNel), None) =>
        Some(itemsWithAllTags(tagNel))
      case (None, Some(catNel)) =>
        Some(itemsInAllCategories(catNel))
      case (None, None) =>
        None
    }
  }
}
