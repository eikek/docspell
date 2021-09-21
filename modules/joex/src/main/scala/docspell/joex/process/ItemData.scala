/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import docspell.common._
import docspell.joex.process.ItemData.AttachmentDates
import docspell.store.records.{RAttachment, RAttachmentMeta, RItem}

/** Data that is carried across all processing tasks.
  *
  * @param item
  *   the stored item record
  * @param attachments
  *   the attachments belonging to the item
  * @param metas
  *   the meta data to each attachment; depending on the state of processing, this may be
  *   empty
  * @param dateLabels
  *   a separate list of found dates
  * @param originFile
  *   a mapping from an attachment id to a filemeta-id containng the source or origin file
  * @param givenMeta
  *   meta data to this item that was not "guessed" from an attachment but given and thus
  *   is always correct
  * @param classifyProposals
  *   these are proposals that were obtained by a trained classifier. There are no
  *   ner-tags, it will only provide a single label
  */
case class ItemData(
    item: RItem,
    attachments: Vector[RAttachment],
    metas: Vector[RAttachmentMeta],
    dateLabels: Vector[AttachmentDates],
    originFile: Map[Ident, Ident], // maps RAttachment.id -> FileMeta.id
    givenMeta: MetaProposalList, // given meta data not associated to a specific attachment
    // a list of tags (names or ids) attached to the item if they exist
    tags: List[String],
    // proposals obtained from the classifier
    classifyProposals: MetaProposalList,
    classifyTags: List[String]
) {

  /** sort by weight; order of equal weights is not important, just choose one others are
    * then suggestions doc-date is only set when given explicitely, not from "guessing"
    */
  def finalProposals: MetaProposalList =
    MetaProposalList
      .flatten(metas.map(_.proposals))
      .filter(_.proposalType != MetaProposalType.DocDate)
      .sortByWeights
      .fillEmptyFrom(classifyProposals)

  def findMeta(attachId: Ident): Option[RAttachmentMeta] =
    metas.find(_.id == attachId)

  def findDates(rm: RAttachmentMeta): Vector[NerDateLabel] =
    dateLabels.find(m => m.rm.id == rm.id).map(_.dates).getOrElse(Vector.empty)

  def mapMeta(
      attachId: Ident,
      lang: Language,
      f: RAttachmentMeta => RAttachmentMeta
  ): ItemData = {
    val item = changeMeta(attachId, lang, f)
    val next = metas.map(a => if (a.id == attachId) item else a)
    copy(metas = next)
  }

  def appendTags(tags: Seq[String]): ItemData =
    copy(tags = (this.tags ++ tags.toList).distinct)

  def changeMeta(
      attachId: Ident,
      lang: Language,
      f: RAttachmentMeta => RAttachmentMeta
  ): RAttachmentMeta =
    f(findOrCreate(attachId, lang))

  def findOrCreate(attachId: Ident, lang: Language): RAttachmentMeta =
    metas.find(_.id == attachId).getOrElse {
      RAttachmentMeta.empty(attachId, lang)
    }

}

object ItemData {

  case class AttachmentDates(rm: RAttachmentMeta, dates: Vector[NerDateLabel]) {
    def toNerLabel: Vector[NerLabel] =
      dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

}
