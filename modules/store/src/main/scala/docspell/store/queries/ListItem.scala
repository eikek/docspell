/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

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
    corrOrg: Option[IdRef],
    corrPerson: Option[IdRef],
    concPerson: Option[IdRef],
    concEquip: Option[IdRef],
    folder: Option[IdRef],
    notes: Option[String]
)
