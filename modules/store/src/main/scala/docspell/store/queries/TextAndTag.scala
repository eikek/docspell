/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

case class TextAndTag(itemId: Ident, text: String, tag: Option[TextAndTag.TagName])

object TextAndTag {
  case class TagName(id: Ident, name: String)
}
