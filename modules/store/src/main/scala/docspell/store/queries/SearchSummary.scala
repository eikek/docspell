/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

case class SearchSummary(
    count: Int,
    tags: List[TagCount],
    cats: List[CategoryCount],
    fields: List[FieldStats],
    folders: List[FolderCount]
)
