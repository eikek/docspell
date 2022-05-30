/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._
import docspell.store.impl.TempFtsTable.ContextEntry

case class ListItem(
    id: Ident,
    name: String,
    state: ItemState,
    date: Timestamp,
    dueDate: Option[Timestamp],
    source: String,
    direction: Direction,
    created: Timestamp,
    corrOrg: Option[IdRef],
    corrPerson: Option[IdRef],
    concPerson: Option[IdRef],
    concEquip: Option[IdRef],
    folder: Option[IdRef],
    notes: Option[String],
    context: Option[String]
) {

  def decodeContext: Option[Either[String, List[ContextEntry]]] =
    context.map(_.trim).filter(_.nonEmpty).map { str =>
      // This is a bit… well. The common denominator for the dbms used is string aggregation
      // when combining multiple matches. So the `ContextEntry` objects are concatenated and
      // separated by comma. TemplateFtsTable ensures than the single entries are all json
      // objects.
      val jsonStr = s"[ $str ]"
      io.circe.parser
        .decode[List[Option[ContextEntry]]](jsonStr)
        .left
        .map(_.getMessage)
        .map(_.flatten)
    }
}
