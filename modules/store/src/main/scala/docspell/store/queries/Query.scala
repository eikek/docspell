package docspell.store.queries

import docspell.common._
import docspell.store.records.RItem

case class Query(
    account: AccountId,
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
    source: Option[String],
    orderAsc: Option[RItem.Table => docspell.store.qb.Column[_]]
)

object Query {
  def empty(account: AccountId): Query =
    Query(
      account,
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
      None,
      None
    )
}
