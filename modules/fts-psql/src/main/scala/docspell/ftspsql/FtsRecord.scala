/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.syntax.all._

import docspell.common.{CollectiveId, Ident, Language}
import docspell.ftsclient.TextData

final case class FtsRecord(
    id: Ident,
    itemId: Ident,
    collective: CollectiveId,
    language: Language,
    attachId: Option[Ident],
    folderId: Option[Ident],
    attachName: Option[String],
    attachContent: Option[String],
    itemName: Option[String],
    itemNotes: Option[String]
)

object FtsRecord {
  def fromTextData(td: TextData): FtsRecord =
    td match {
      case TextData.Attachment(
            item,
            attachId,
            collective,
            folder,
            language,
            name,
            text
          ) =>
        FtsRecord(
          td.id,
          item,
          collective,
          language,
          attachId.some,
          folder,
          name,
          text,
          None,
          None
        )
      case TextData.Item(item, collective, folder, name, notes, language) =>
        FtsRecord(
          td.id,
          item,
          collective,
          language,
          None,
          folder,
          None,
          None,
          name,
          notes
        )
    }
}
