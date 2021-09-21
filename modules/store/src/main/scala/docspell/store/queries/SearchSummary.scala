/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

case class SearchSummary(
    count: Int,
    tags: List[TagCount],
    cats: List[CategoryCount],
    fields: List[FieldStats],
    folders: List[FolderCount]
)
