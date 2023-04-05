/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.common._

import io.circe._

final class Field(val name: String) extends AnyVal {

  override def toString(): String = s"Field($name)"
}

object Field {

  def apply(name: String): Field =
    new Field(name)

  val id = Field("id")
  val itemId = Field("itemId")
  val collectiveId = Field("collectiveId")
  val attachmentId = Field("attachmentId")
  val discriminator = Field("discriminator")
  val attachmentName = Field("attachmentName")
  val content = Field("content")
  val content_de = contentField(Language.German)
  val content_en = contentField(Language.English)
  val content_fr = contentField(Language.French)
  val content_kh = contentField(Language.Khmer)
  val itemName = Field("itemName")
  val itemNotes = Field("itemNotes")
  val folderId = Field("folder")

  val contentLangFields = Language.all
    .map(contentField)

  def contentField(lang: Language): Field =
    if (lang == Language.Czech) Field(s"content_cz")
    else Field(s"content_${lang.iso2}")

  implicit val jsonEncoder: Encoder[Field] =
    Encoder.encodeString.contramap(_.name)
}
