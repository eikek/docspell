package docspell.ftssolr

import io.circe._

final class Field(val name: String) extends AnyVal {

  override def toString(): String = s"Field($name)"
}

object Field {

  def apply(name: String): Field =
    new Field(name)


  val discriminator = Field("discriminator")
  val id = Field("id")
  val itemId = Field("itemId")
  val collectiveId = Field("collectiveId")
  val attachmentId = Field("attachmentId")
  val attachmentName = Field("attachmentName")
  val content = Field("content")
  val itemName = Field("itemName")
  val itemNotes = Field("itemNotes")


  implicit val jsonEncoder: Encoder[Field] =
    Encoder.encodeString.contramap(_.name)
}
