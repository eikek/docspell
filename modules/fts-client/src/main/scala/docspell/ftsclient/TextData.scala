package docspell.ftsclient

import docspell.common._

sealed trait TextData {

  def id: Ident

  def item: Ident

  def collective: Ident

}

object TextData {

  final case class Attachment(
      item: Ident,
      attachId: Ident,
      collective: Ident,
      name: Option[String],
      text: Option[String]
  ) extends TextData {

    val id = item / attachId

  }

  def attachment(
      item: Ident,
      attachId: Ident,
      collective: Ident,
      name: Option[String],
      text: Option[String]
  ): TextData =
    Attachment(item, attachId, collective, name, text)

  final case class Item(
      item: Ident,
      collective: Ident,
      name: Option[String],
      notes: Option[String]
  ) extends TextData {

    val id = Ident.unsafe("item") / item

  }

  def item(
      item: Ident,
      collective: Ident,
      name: Option[String],
      notes: Option[String]
  ): TextData =
    Item(item, collective, name, notes)
}
