package docspell.ftssolr

object Fields {
  val discriminator = "discriminator"
  val id = "id"
  val itemId = "itemId"
  val collectiveId = "collectiveId"

  object Attachment {
    val attachmentId = "attachmentId"
    val attachmentName = "attachmentName"
    val content = "content"
  }

  object Item {
    val itemName = "itemName"
    val itemNotes = "itemNotes"
  }
}
