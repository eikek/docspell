/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.ftsclient

import docspell.common._

sealed trait TextData {

  def id: Ident

  def item: Ident

  def collective: Ident

  def folder: Option[Ident]

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
      collective: Ident,
      folder: Option[Ident],
      lang: Language,
      name: Option[String],
      text: Option[String]
  ) extends TextData {

    val id = item / attachId

  }

  def attachment(
      item: Ident,
      attachId: Ident,
      collective: Ident,
      folder: Option[Ident],
      lang: Language,
      name: Option[String],
      text: Option[String]
  ): TextData =
    Attachment(item, attachId, collective, folder, lang, name, text)

  final case class Item(
      item: Ident,
      collective: Ident,
      folder: Option[Ident],
      name: Option[String],
      notes: Option[String]
  ) extends TextData {

    val id = Ident.unsafe("item") / item

  }

  def item(
      item: Ident,
      collective: Ident,
      folder: Option[Ident],
      name: Option[String],
      notes: Option[String]
  ): TextData =
    Item(item, collective, folder, name, notes)

}
