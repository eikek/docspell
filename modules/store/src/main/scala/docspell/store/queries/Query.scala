/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.fts.RFtsResult
import docspell.store.qb.DSL._
import docspell.store.qb.{Column, OrderBy}
import docspell.store.records.RItem

case class Query(fix: Query.Fix, cond: Query.QueryCond) {
  def withCond(f: Query.QueryCond => Query.QueryCond): Query =
    copy(cond = f(cond))

  def andCond(c: ItemQuery.Expr): Query =
    withCond {
      case Query.QueryExpr(Some(q)) =>
        Query.QueryExpr(ItemQuery.Expr.and(q, c))

      case Query.QueryExpr(None) =>
        Query.QueryExpr(c)
    }

  def withOrder(orderAsc: RItem.Table => Column[_]): Query =
    withFix(_.copy(order = Some(_.byItemColumnAsc(orderAsc))))

  def withFix(f: Query.Fix => Query.Fix): Query =
    copy(fix = f(fix))

  def isEmpty: Boolean =
    fix.isEmpty && cond.isEmpty

  def nonEmpty: Boolean =
    !isEmpty
}

object Query {
  trait OrderSelect {
    def item: RItem.Table
    def fts: Option[RFtsResult.Table]

    def byDefault: OrderBy =
      OrderBy.desc(coalesce(item.itemDate.s, item.created.s).s)

    def byItemColumnAsc(f: RItem.Table => Column[_]): OrderBy =
      OrderBy.asc(coalesce(f(item).s, item.created.s).s)

    def byScore: OrderBy =
      fts.map(t => OrderBy.desc(t.score.s)).getOrElse(byDefault)
  }

  def apply(fix: Fix): Query =
    Query(fix, QueryExpr(None))

  case class Fix(
      account: AccountId,
      query: Option[ItemQuery.Expr],
      order: Option[OrderSelect => OrderBy]
  ) {

    def isEmpty: Boolean =
      query.isEmpty

    def andQuery(expr: ItemQuery.Expr): Fix =
      copy(query = query.map(e => ItemQuery.Expr.and(e, expr)).orElse(Some(expr)))
  }

  sealed trait QueryCond {
    def isEmpty: Boolean

    def nonEmpty: Boolean =
      !isEmpty
  }

  case class QueryExpr(q: Option[ItemQuery.Expr]) extends QueryCond {
    def isEmpty: Boolean =
      q.isEmpty
  }

  object QueryExpr {
    def apply(q: ItemQuery.Expr): QueryExpr =
      QueryExpr(Some(q))
  }

  def all(account: AccountId): Query =
    Query(Fix(account, None, None), QueryExpr(None))

}
