package docspell.joex.process

import docspell.common.{Ident, NerDateLabel, NerLabel}
import docspell.joex.process.ItemData.AttachmentDates
import docspell.store.records.{RAttachment, RAttachmentMeta, RItem}

case class ItemData( item: RItem
                   , attachments: Vector[RAttachment]
                   , metas: Vector[RAttachmentMeta]
                   , dateLabels: Vector[AttachmentDates]) {

  def findMeta(attachId: Ident): Option[RAttachmentMeta] =
    metas.find(_.id == attachId)

  def findDates(rm: RAttachmentMeta): Vector[NerDateLabel] =
    dateLabels.find(m => m.rm.id == rm.id).map(_.dates).getOrElse(Vector.empty)
}


object ItemData {

  case class AttachmentDates(rm: RAttachmentMeta, dates: Vector[NerDateLabel]) {
    def toNerLabel: Vector[NerLabel] =
      dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

}