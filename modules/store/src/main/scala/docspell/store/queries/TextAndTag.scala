/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

case class TextAndTag(itemId: Ident, text: String, tag: Option[TextAndTag.TagName])

object TextAndTag {
  case class TagName(id: Ident, name: String)
}
