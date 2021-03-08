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

  case class Fix(
      account: AccountId,
      itemIds: Option[Set[Ident]],
      orderAsc: Option[RItem.Table => Column[_]]
  ) {

    def isEmpty: Boolean =
      itemIds.isEmpty
  }

  sealed trait QueryCond {
    def isEmpty: Boolean

    def nonEmpty: Boolean =
      !isEmpty
  }

  case class QueryForm(
      name: Option[String],
      states: Seq[ItemState],
      direction: Option[Direction],
      corrPerson: Option[Ident],
      corrOrg: Option[Ident],
      concPerson: Option[Ident],
      concEquip: Option[Ident],
      folder: Option[Ident],
      tagsInclude: List[Ident],
      tagsExclude: List[Ident],
      tagCategoryIncl: List[String],
      tagCategoryExcl: List[String],
      dateFrom: Option[Timestamp],
      dateTo: Option[Timestamp],
      dueDateFrom: Option[Timestamp],
      dueDateTo: Option[Timestamp],
      allNames: Option[String],
      itemIds: Option[Set[Ident]],
      customValues: Seq[CustomValue],
      source: Option[String]
  ) extends QueryCond {

    def isEmpty: Boolean =
      this == QueryForm.empty
  }
  object QueryForm {
    val empty =
      QueryForm(
        None,
        Seq.empty,
        None,
        None,
        None,
        None,
        None,
        None,
        Nil,
        Nil,
        Nil,
        Nil,
        None,
        None,
        None,
        None,
        None,
        None,
        Seq.empty,
        None
      )
  }

  case class QueryExpr(q: ItemQuery) extends QueryCond {
    def isEmpty: Boolean =
      q.expr == ItemQuery.all.expr
  }

  def empty(account: AccountId): Query =
    Query(Fix(account, None, None), QueryForm.empty)

}
