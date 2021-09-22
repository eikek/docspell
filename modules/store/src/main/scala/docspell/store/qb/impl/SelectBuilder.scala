/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.impl

import cats.data.NonEmptyList

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object SelectBuilder {
  val comma = fr","
  val asc = fr" ASC"
  val desc = fr" DESC"
  val intersect = fr" INTERSECT"
  val union = fr" UNION ALL"

  def apply(q: Select): Fragment =
    build(q)

  def build(q: Select): Fragment =
    q match {
      case sq: Select.SimpleSelect =>
        val sel = if (sq.distinctFlag) fr"SELECT DISTINCT" else fr"SELECT"
        sel ++ buildSimple(sq)

      case Select.RawSelect(f) =>
        f

      case Select.Union(q, qs) =>
        qs.prepended(q).map(build).reduce(_ ++ union ++ _)

      case Select.Intersect(q, qs) =>
        qs.prepended(q).map(build).reduce(_ ++ intersect ++ _)

      case Select.Ordered(q, ob, obs) =>
        val order = obs.prepended(ob).map(orderBy).reduce(_ ++ comma ++ _)
        build(q) ++ fr" ORDER BY" ++ order

      case Select.Limit(q, batch) =>
        build(q) ++ buildBatch(batch)

      case Select.WithCte(cte, moreCte, query) =>
        val ctes = moreCte.prepended(cte)
        fr"WITH" ++ ctes.map(buildCte).reduce(_ ++ comma ++ _) ++ fr" " ++ build(query)
    }

  def buildSimple(sq: Select.SimpleSelect): Fragment = {
    val f0 = sq.projection.map(selectExpr).reduceLeft(_ ++ comma ++ _)
    val f1 = fromExpr(sq.from)
    val f2 = cond(sq.where)
    val f3 = sq.groupBy.map(groupBy).getOrElse(Fragment.empty)
    f0 ++ f1 ++ f2 ++ f3
  }

  def orderBy(ob: OrderBy): Fragment = {
    val f1 = selectExpr(ob.expr)
    val f2 = ob.orderType match {
      case OrderBy.OrderType.Asc =>
        asc
      case OrderBy.OrderType.Desc =>
        desc
    }
    f1 ++ f2
  }

  def selectExpr(se: SelectExpr): Fragment =
    SelectExprBuilder.build(se)

  def fromExpr(fr: FromExpr): Fragment =
    FromExprBuilder.build(fr)

  def cond(c: Condition): Fragment =
    c match {
      case Condition.UnitCondition =>
        Fragment.empty
      case _ =>
        fr" WHERE" ++ ConditionBuilder.build(c)
    }

  def groupBy(gb: GroupBy): Fragment = {
    val f0 = gb.names.prepended(gb.name).map(selectExpr).reduce(_ ++ comma ++ _)
    val f1 = gb.having.map(cond).getOrElse(Fragment.empty)
    fr"GROUP BY" ++ f0 ++ f1
  }

  def buildCte(bind: CteBind): Fragment =
    bind match {
      case CteBind(name, cols, select) =>
        val colDef =
          NonEmptyList
            .fromFoldable(cols)
            .map(nel =>
              nel
                .map(col => CommonBuilder.columnNoPrefix(col))
                .reduceLeft(_ ++ comma ++ _)
            )
            .map(f => sql"(" ++ f ++ sql")")
            .getOrElse(Fragment.empty)

        Fragment.const0(name.tableName) ++ colDef ++ sql" AS (" ++ build(select) ++ sql")"
    }

  def buildBatch(b: Batch): Fragment = {
    val limitFrag =
      if (b.limit != Int.MaxValue) fr" LIMIT ${b.limit}"
      else Fragment.empty

    val offsetFrag =
      if (b.offset != 0) fr" OFFSET ${b.offset}"
      else Fragment.empty

    limitFrag ++ offsetFrag
  }
}
