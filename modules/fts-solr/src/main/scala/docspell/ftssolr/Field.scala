package docspell.ftssolr

import docspell.common._

import io.circe._

final class Field(val name: String) extends AnyVal {

  override def toString(): String = s"Field($name)"
}

object Field {

  def apply(name: String): Field =
    new Field(name)

  val id             = Field("id")
  val itemId         = Field("itemId")
  val collectiveId   = Field("collectiveId")
  val attachmentId   = Field("attachmentId")
  val discriminator  = Field("discriminator")
  val attachmentName = Field("attachmentName")
  val content        = Field("content")
  val content_de     = Field("content_de")
  val content_en     = Field("content_en")
  val itemName       = Field("itemName")
  val itemNotes      = Field("itemNotes")

  def contentField(lang: Language): Field =
    lang match {
      case Language.German =>
        Field.content_de
      case Language.English =>
        Field.content_en
    }

  implicit val jsonEncoder: Encoder[Field] =
    Encoder.encodeString.contramap(_.name)
}
