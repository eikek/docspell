/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.ftsclient

import docspell.common._

/** A fulltext query.
  *
  * The query itself is a raw string. Each implementation may
  * interpret it according to the system in use.
  *
  * Searches must only look for given collective and in the given list
  * of item ids, if it is non-empty. If the item set is empty, then
  * don't restrict the result in this way.
  *
  * The set of folders must be used to restrict the results only to
  * items that have one of the folders set or no folder set. If the
  * set is empty, the restriction does not apply.
  */
final case class FtsQuery(
    q: String,
    collective: Ident,
    items: Set[Ident],
    folders: Set[Ident],
    limit: Int,
    offset: Int,
    highlight: FtsQuery.HighlightSetting
) {

  def nextPage: FtsQuery =
    copy(offset = limit + offset)

  def withFolders(fs: Set[Ident]): FtsQuery =
    copy(folders = fs)
}

object FtsQuery {

  case class HighlightSetting(pre: String, post: String)

  object HighlightSetting {
    val default = HighlightSetting("**", "**")
  }
}
