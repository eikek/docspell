/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._
import docspell.store.records._

import bitpeace.FileMeta

case class ItemData(
    item: RItem,
    corrOrg: Option[ROrganization],
    corrPerson: Option[RPerson],
    concPerson: Option[RPerson],
    concEquip: Option[REquipment],
    inReplyTo: Option[IdRef],
    folder: Option[IdRef],
    tags: Vector[RTag],
    attachments: Vector[(RAttachment, FileMeta)],
    sources: Vector[(RAttachmentSource, FileMeta)],
    archives: Vector[(RAttachmentArchive, FileMeta)],
    customFields: Vector[ItemFieldValue]
) {

  def filterCollective(coll: Ident): Option[ItemData] =
    if (item.cid == coll) Some(this) else None
}
