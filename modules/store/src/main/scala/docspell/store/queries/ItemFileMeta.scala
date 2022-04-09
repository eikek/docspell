/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._
import docspell.store.records.RFileMeta

/** Almost like [[ListItem]] but without notes and at file level. */
final case class ItemFileMeta(
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
    fileName: Option[String],
    fileMeta: RFileMeta
)
