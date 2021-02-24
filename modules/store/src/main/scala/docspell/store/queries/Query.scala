package docspell.store.queries

import docspell.common._
import docspell.store.qb.Column
import docspell.store.records.RItem

case class Query(fix: Query.Fix, cond: Query.QueryCond) {
  def withCond(f: Query.QueryCond => Query.QueryCond): Query =
    copy(cond = f(cond))

  def withOrder(orderAsc: RItem.Table => Column[_]): Query =
    copy(fix = fix.copy(orderAsc = Some(orderAsc)))
}

object Query {

  case class Fix(account: AccountId, orderAsc: Option[RItem.Table => Column[_]])

  case class QueryCond(
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
  )
  object QueryCond {
    val empty =
      QueryCond(
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

  def empty(account: AccountId): Query =
    Query(Fix(account, None), QueryCond.empty)

}
