package docspell.store.queries

import docspell.common._

case class ListItem(
    id: Ident,
    name: String,
    state: ItemState,
    date: Timestamp,
    dueDate: Option[Timestamp],
    source: String,
    direction: Direction,
    created: Timestamp,
    fileCount: Int,
    corrOrg: Option[IdRefAbbrev],
    corrPerson: Option[IdRef],
    concPerson: Option[IdRef],
    concEquip: Option[IdRef],
    folder: Option[IdRef],
    notes: Option[String]
)
