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
    folders: List[FolderCount],
    corrOrgs: List[IdRefCount],
    corrPers: List[IdRefCount],
    concPers: List[IdRefCount],
    concEquip: List[IdRefCount]
) {

  def onlyExisting: SearchSummary =
    SearchSummary(
      count,
      tags.filter(_.count > 0),
      cats.filter(_.count > 0),
      fields.filter(_.count > 0),
      folders.filter(_.count > 0),
      corrOrgs = corrOrgs.filter(_.count > 0),
      corrPers = corrPers.filter(_.count > 0),
      concPers = concPers.filter(_.count > 0),
      concEquip = concEquip.filter(_.count > 0)
    )
}
