package docspell.store.queries

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.qb.Column
import docspell.store.records.RItem

case class Query(fix: Query.Fix, cond: Query.QueryCond) {
  def withCond(f: Query.QueryCond => Query.QueryCond): Query =
    copy(cond = f(cond))

  def withOrder(orderAsc: RItem.Table => Column[_]): Query =
    withFix(_.copy(orderAsc = Some(orderAsc)))

  def withFix(f: Query.Fix => Query.Fix): Query =
    copy(fix = f(fix))

  def isEmpty: Boolean =
    fix.isEmpty && cond.isEmpty

  def nonEmpty: Boolean =
    !isEmpty
}

object Query {

  def apply(fix: Fix): Query =
    Query(fix, QueryExpr(None))

  case class Fix(
      account: AccountId,
      query: Option[ItemQuery.Expr],
      orderAsc: Option[RItem.Table => Column[_]]
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
