package docspell.website

import cats.syntax.option._
import docspell.common.MetaProposal.Candidate
import docspell.common._
import docspell.joex.process.ItemData
import docspell.store.records.{RAttachment, RAttachmentMeta, RItem}
import io.circe.syntax._

object ItemDataExample extends Helper {

  private val proposals: MetaProposalList = MetaProposalList(
    List(
      MetaProposal(MetaProposalType.CorrOrg, Candidate(idRef("Acme AG"), Set.empty)),
      MetaProposal(
        MetaProposalType.ConcPerson,
        Candidate(idRef("Derek Jeter"), Set.empty)
      )
    )
  )

  private val givenProposals: MetaProposalList = MetaProposalList.empty

  val example = ItemData(
    item = RItem(
      id = id("UyZ-item-id"),
      cid = cid,
      name = "yearly report 2021",
      itemDate = date20220514.some,
      source = "webapp",
      direction = Direction.Incoming,
      state = ItemState.Processing,
      corrOrg = None,
      corrPerson = None,
      concPerson = None,
      concEquipment = None,
      inReplyTo = None,
      dueDate = None,
      created = date20220514,
      updated = date20220514,
      notes = None,
      folderId = None
    ),
    attachments = Vector(
      RAttachment(
        id = id("Apa-attach-id"),
        itemId = id("UyZ-item-id"),
        fileId = FileKey(cid, FileCategory.AttachmentConvert, id("abcxyz")),
        position = 0,
        created = date20220514,
        name = "report_year_2021.pdf".some
      )
    ),
    metas = Vector(
      RAttachmentMeta(
        id = id("Apa-attach-id"),
        content = "this is the extracted text …".some,
        nerlabels = Nil,
        proposals = proposals,
        pages = 2.some,
        language = Language.English.some
      )
    ),
    dateLabels = Vector.empty,
    originFile = Map(
      id("Apa-attach-id") -> FileKey(cid, FileCategory.AttachmentSource, "yanetar".id)
    ),
    givenMeta = givenProposals,
    tags = List("tag-1"),
    classifyProposals = MetaProposalList.empty,
    classifyTags = List("invoice")
  )

  val exampleJson = example.asJson.spaces2
}
