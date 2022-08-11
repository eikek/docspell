/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftsclient

import docspell.common._

sealed trait TextData {

  def id: Ident

  def item: Ident

  def collective: CollectiveId

  def folder: Option[Ident]

  def language: Language

  final def fold[A](f: TextData.Attachment => A, g: TextData.Item => A): A =
    this match {
      case a: TextData.Attachment => f(a)
      case a: TextData.Item       => g(a)
    }
}

object TextData {

  final case class Attachment(
      item: Ident,
      attachId: Ident,
      collective: CollectiveId,
      folder: Option[Ident],
      language: Language,
      name: Option[String],
      text: Option[String]
  ) extends TextData {

    val id = item / attachId

  }

  def attachment(
      item: Ident,
      attachId: Ident,
      collective: CollectiveId,
      folder: Option[Ident],
      lang: Language,
      name: Option[String],
      text: Option[String]
  ): TextData =
    Attachment(item, attachId, collective, folder, lang, name, text)

  final case class Item(
      item: Ident,
      collective: CollectiveId,
      folder: Option[Ident],
      name: Option[String],
      notes: Option[String],
      language: Language
  ) extends TextData {

    val id = Ident.unsafe("item") / item

  }

  def item(
      item: Ident,
      collective: CollectiveId,
      folder: Option[Ident],
      name: Option[String],
      notes: Option[String],
      lang: Language
  ): TextData =
    Item(item, collective, folder, name, notes, lang)

}
