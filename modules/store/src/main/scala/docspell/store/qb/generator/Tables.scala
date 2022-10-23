/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.generator

import docspell.store.records._

final case class Tables(
    item: RItem.Table,
    corrOrg: ROrganization.Table,
    corrPers: RPerson.Table,
    concPers: RPerson.Table,
    concEquip: REquipment.Table,
    folder: RFolder.Table,
    attach: RAttachment.Table,
    meta: RAttachmentMeta.Table
)
