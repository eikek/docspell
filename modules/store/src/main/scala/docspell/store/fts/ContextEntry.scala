/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.fts

import docspell.store.impl.DoobieMeta.jsonMeta

import doobie.Meta
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** Highlighting context from a fulltext search.
  *
  * @param name
  *   the document name, either attachment name or "item"
  * @param context
  *   lines with highlighting infos
  */
case class ContextEntry(name: String, context: List[String])

object ContextEntry {
  implicit val jsonDecoder: Decoder[ContextEntry] = deriveDecoder
  implicit val jsonEncoder: Encoder[ContextEntry] = deriveEncoder

  implicit val meta: Meta[ContextEntry] =
    jsonMeta[ContextEntry]
}
