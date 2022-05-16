package docspell.website

import cats.syntax.all._
import docspell.addons.out.{AddonOutput, ItemFile, NewFile, NewItem}
import docspell.addons.out.NewFile.{Meta => FileMeta}
import docspell.addons.out.NewItem.{Meta => ItemMeta}
import docspell.common._
import docspell.common.bc.{AttachmentAction, BackendCommand, ItemAction}
import io.circe.syntax._

object AddonOutputExample extends Helper {

  val example = AddonOutput(
    commands = List(
      BackendCommand.ItemUpdate(
        itemId = id("XabZ-item-id"),
        actions = List(
          ItemAction.AddTags(Set("tag1", "tag2")),
          ItemAction.ReplaceTags(Set("tagX", "tagY")),
          ItemAction.RemoveTags(Set("tag0", "tag9")),
          ItemAction.RemoveTagsCategory(Set("doc-type")),
          ItemAction.SetFolder("folder-name".some),
          ItemAction.SetCorrOrg(id("OaIy-org-ID").some),
          ItemAction.SetCorrPerson(id("OaIy-person-ID").some),
          ItemAction.SetConcPerson(id("AEiae-person-ID").some),
          ItemAction.SetConcEquipment(id("AEiae-equipment-ID").some),
          ItemAction.SetField(id("eur"), "12.99"),
          ItemAction.SetName("new item name"),
          ItemAction.SetNotes("replace notes with this".some),
          ItemAction.AddNotes("More notes appended", Some("-----"))
        )
      ),
      BackendCommand
        .AttachmentUpdate(
          itemId = id("XabZ-item-id"),
          attachId = id("Atca-attach-id"),
          actions = List(
            AttachmentAction.SetExtractedText("replace extracted text with this".some)
          )
        )
    ),
    files = List(
      ItemFile(
        id("iZtb-item-id"),
        textFiles = Map("attach-id" -> "newtext.txt"),
        pdfFiles = Map("attach-id" -> "better.pdf"),
        previewImages = Map("attach-id" -> "better-preview.png"),
        newFiles = List(
          NewFile(
            metadata = FileMeta(
              language = Some(Language.English),
              skipDuplicate = Some(true),
              attachmentsOnly = Some(false)
            ),
            file = "new-file1.docx"
          ),
          NewFile(
            metadata = FileMeta(
              language = Some(Language.German),
              skipDuplicate = Some(true),
              attachmentsOnly = Some(false)
            ),
            file = "new-file2.pdf"
          )
        )
      )
    ),
    newItems = List(
      NewItem(
        metadata = ItemMeta(
          language = Some(Language.English),
          direction = Direction.Incoming.some,
          folderId = id("my-folder").some,
          source = "the-addon-x".some,
          skipDuplicate = true.some,
          tags = List("tag1", "tag2").some,
          attachmentsOnly = None
        ).some,
        files = List("a-file.pdf", "another.jpg")
      )
    )
  )

  def exampleJson =
    example.asJson.spaces2
}
