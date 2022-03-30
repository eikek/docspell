/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common.Ident
import docspell.store.records.RTag

case class ListItemWithTags(
    item: ListItem,
    tags: List[RTag],
    attachments: List[AttachmentLight],
    customfields: List[ItemFieldValue],
    relatedItems: List[Ident]
)
