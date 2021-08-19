/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RItemProposal(
    itemId: Ident,
    classifyProposals: MetaProposalList,
    classifyTags: List[IdRef],
    created: Timestamp
)

object RItemProposal {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "item_proposal"

    val itemId            = Column[Ident]("itemid", this)
    val classifyProposals = Column[MetaProposalList]("classifier_proposals", this)
    val classifyTags      = Column[List[IdRef]]("classifier_tags", this)
    val created           = Column[Timestamp]("created", this)
    val all = NonEmptyList.of[Column[_]](itemId, classifyProposals, classifyTags, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RItemProposal): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.itemId},${v.classifyProposals},${v.classifyTags},${v.created}"
    )

  def update(v: RItemProposal): ConnectionIO[Int] =
    DML.update(
      T,
      T.itemId === v.itemId,
      DML.set(
        T.classifyProposals.setTo(v.classifyProposals),
        T.classifyTags.setTo(v.classifyTags)
      )
    )

  def deleteByItem(itemId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.itemId === itemId)

  def exists(itemId: Ident): ConnectionIO[Boolean] =
    Select(select(countAll), from(T), T.itemId === itemId).build
      .query[Int]
      .unique
      .map(_ > 0)

}
