/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import java.time.LocalDate

import cats.data.{NonEmptyList => Nel}
import cats.implicits._

import docspell.common._
import docspell.store.fts.RFtsResult
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie.implicits._
import doobie.{Query => _, _}

private[queries] object QItemFieldStats {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]

  private val cf = RCustomField.as("cf")
  private val cv = RCustomFieldValue.as("cvf")

  final case class StatsItemContext(
      folderIds: Set[Ident],
      matchingSubselect: Select,
      matchingItemIds: List[Ident],
      matchCount: Int
  )

  /** When the match set is small, use literal `item_id` values so PostgreSQL can use
    * `custom_field_value_item_id_idx` instead of nested-looping over a sub-select of
    * matching items.
    */
  private val fieldStatsItemIdLiteralMax = 200

  def resolveStatsItemContext(
      fix: Query.Fix,
      today: LocalDate,
      cond: Query.QueryCond,
      ftsTable: Option[RFtsResult.Table]
  ): ConnectionIO[StatsItemContext] =
    for {
      folderIds <- QFolder.getMemberFolders(fix.account.collectiveId, fix.account.userId)
      folderIdsOpt = Some(folderIds)
      matchingSubselect = QItem.statsItemMatchingIdsSelect(
        fix,
        today,
        cond,
        ftsTable,
        folderIdsOpt
      )
      matchCount <- QItem.statsItemMatchCount(
        fix,
        today,
        cond,
        ftsTable,
        folderIdsOpt
      )
      matchingItemIds <-
        if (matchCount == 0) Nil.pure[ConnectionIO]
        else if (matchCount <= fieldStatsItemIdLiteralMax)
          matchingSubselect.build.query[Ident].to[List]
        else Nil.pure[ConnectionIO]
    } yield StatsItemContext(folderIds, matchingSubselect, matchingItemIds, matchCount)

  private def cvItemFilter(ctx: StatsItemContext): Option[Condition] =
    if (ctx.matchCount == 0) None
    else if (ctx.matchingItemIds.nonEmpty)
      Some(cvItemIdFilter(ctx.matchingItemIds, ctx.matchingSubselect))
    else
      Some(cv.itemId.in(ctx.matchingSubselect))

  private def cvItemIdFilter(
      itemIds: List[Ident],
      matchingSubselect: Select
  ): Condition =
    itemIds match {
      case id :: Nil =>
        cv.itemId === id
      case _ =>
        Nel.fromList(itemIds) match {
          case Some(nel) if itemIds.length <= fieldStatsItemIdLiteralMax =>
            cv.itemId.in(nel)
          case _ =>
            cv.itemId.in(matchingSubselect)
        }
    }

  private def fieldStatsBase(
      coll: CollectiveId,
      cvFilter: Condition
  ): Select =
    Select(
      select(cf.all),
      from(cv).innerJoin(cf, cf.id === cv.field && cf.cid === coll),
      cvFilter
    )

  private val fieldStatsNumTypes =
    Nel.of(CustomFieldType.money, CustomFieldType.numeric)

  private val fieldStatsBasicFields: Nel[SelectExpr] =
    Nel.of(
      count(cv.itemId).as("fc"),
      const(0).as("favg"),
      const(0).as("fsum"),
      const(0).as("fmax"),
      const(0).as("fmin")
    )

  private val fieldStatsNumericFields: Nel[SelectExpr] = {
    val valueNum = castNumeric(cv.value.s).s
    Nel.of(
      count(cv.itemId).as("fc"),
      avg(valueNum).as("favg"),
      sum(valueNum).as("fsum"),
      max(valueNum).as("fmax"),
      min(valueNum).as("fmin")
    )
  }

  def searchFieldSummary(today: LocalDate, ftsTable: Option[RFtsResult.Table])(
      q: Query
  ): ConnectionIO[List[FieldStats]] =
    resolveStatsItemContext(q.fix, today, q.cond, ftsTable).flatMap { ctx =>
      searchFieldSummaryFromContext(q.fix.account.collectiveId, ctx)
    }

  def searchFieldSummaryFromContext(
      coll: CollectiveId,
      ctx: StatsItemContext
  ): ConnectionIO[List[FieldStats]] =
    cvItemFilter(ctx) match {
      case None =>
        List.empty[FieldStats].pure[ConnectionIO]

      case Some(cvFilter) =>
        val largeSet = ctx.matchCount > fieldStatsItemIdLiteralMax
        val base = fieldStatsBase(coll, cvFilter).groupBy(GroupBy(cf.all))
        val query =
          if (largeSet) {
            // Dashboard/search UI only displays numeric fields with sum > 0; skip text
            // fields when the match set is too large to aggregate cheaply.
            base
              .withSelect(select(cf.all).concatNel(fieldStatsNumericFields))
              .changeWhere(c => c && cf.ftype.in(fieldStatsNumTypes))
              .build
              .query[FieldStats]
              .to[List]
          } else {
            union(
              base
                .withSelect(select(cf.all).concatNel(fieldStatsBasicFields))
                .changeWhere(c => c && cf.ftype.notIn(fieldStatsNumTypes)),
              base
                .withSelect(select(cf.all).concatNel(fieldStatsNumericFields))
                .changeWhere(c => c && cf.ftype.in(fieldStatsNumTypes))
            ).build.query[FieldStats].to[List]
          }

        val fallback =
          base
            .withSelect(select(cf.all).concatNel(fieldStatsBasicFields))
            .build
            .query[FieldStats]
            .to[List]

        query.attemptSql.flatMap {
          case Right(res) =>
            res.pure[ConnectionIO]
          case Left(ex) =>
            logger
              .error(ex)(
                s"Calculating custom field summary failed. You may have invalid custom field values according to their type."
              ) *> fallback
        }
    }

  def searchFieldDefinitionCount(
      ctx: StatsItemContext
  )(q: Query): ConnectionIO[Int] = {
    val coll = q.fix.account.collectiveId
    cvItemFilter(ctx) match {
      case None =>
        0.pure[ConnectionIO]
      case Some(filter) =>
        fieldStatsBase(coll, filter)
          .changeWhere(c => c && cf.ftype.notIn(fieldStatsNumTypes))
          .withSelect(Nel.of(countDistinct(cf.id).as("num")))
          .build
          .query[Int]
          .unique
    }
  }
}
