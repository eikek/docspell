/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.store.impl.TempFtsTable
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.RItem

trait FtsSupport {

  implicit final class SelectOps(select: Select) {
    def joinFtsIdOnly(
        itemTable: RItem.Table,
        ftsTable: Option[TempFtsTable.Table]
    ): Select =
      ftsTable match {
        case Some(ftst) =>
          val tt = cteTable(ftst)
          select
            .appendCte(ftst.distinctCteSimple(tt.tableName))
            .changeFrom(_.prepend(from(itemTable).innerJoin(tt, itemTable.id === tt.id)))
        case None =>
          select
      }

    def joinFtsDetails(
        itemTable: RItem.Table,
        ftsTable: Option[TempFtsTable.Table]
    ): Select =
      ftsTable match {
        case Some(ftst) =>
          val tt = cteTable(ftst)
          select
            .appendCte(ftst.distinctCte(tt.tableName))
            .changeFrom(_.prepend(from(itemTable).innerJoin(tt, itemTable.id === tt.id)))
        case None =>
          select
      }

    def ftsCondition(
        itemTable: RItem.Table,
        ftsTable: Option[TempFtsTable.Table]
    ): Select =
      ftsTable match {
        case Some(ftst) =>
          val ftsIds = Select(ftst.id.s, from(ftst)).distinct
          select.changeWhere(c => c && itemTable.id.in(ftsIds))
        case None =>
          select
      }
  }

  def cteTable(ftsTable: TempFtsTable.Table) =
    ftsTable.copy(tableName = "cte_fts")
}

object FtsSupport extends FtsSupport
