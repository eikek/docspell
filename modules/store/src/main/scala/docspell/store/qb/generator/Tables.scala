package docspell.store.qb.generator

import docspell.store.queries.AttachCountTable
import docspell.store.records._

final case class Tables(
    item: RItem.Table,
    corrOrg: ROrganization.Table,
    corrPers: RPerson.Table,
    concPers: RPerson.Table,
    concEquip: REquipment.Table,
    folder: RFolder.Table,
    attach: RAttachment.Table,
    meta: RAttachmentMeta.Table,
    attachCount: AttachCountTable
)
