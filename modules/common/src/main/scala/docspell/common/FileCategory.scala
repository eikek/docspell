/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import docspell.common

import io.circe.{Decoder, Encoder}

/** This is used to have a rough idea for what a file is used in the system. It is part of
  * the file-key to identify a file, backends could ignore it, since the file-id (the last
  * part of the file-key) should be globally unique anyways.
  */
sealed trait FileCategory { self: Product =>
  final def id: Ident =
    Ident.unsafe(self.productPrefix.toLowerCase)

  def toFileKey(collective: CollectiveId, fileId: Ident): FileKey =
    common.FileKey(collective, this, fileId)
}

object FileCategory {
  // Impl note: Changing constants here requires a database migration!

  case object AttachmentSource extends FileCategory
  case object AttachmentConvert extends FileCategory
  case object PreviewImage extends FileCategory
  case object Classifier extends FileCategory
  case object DownloadAll extends FileCategory
  case object Addon extends FileCategory

  val all: NonEmptyList[FileCategory] =
    NonEmptyList.of(
      AttachmentSource,
      AttachmentConvert,
      PreviewImage,
      Classifier,
      DownloadAll,
      Addon
    )

  def fromString(str: String): Either[String, FileCategory] =
    all.find(_.id.id == str).toRight(s"Unknown category: $str")

  implicit val jsonDecoder: Decoder[FileCategory] =
    Decoder[String].emap(fromString)

  implicit val jsonEncoder: Encoder[FileCategory] =
    Encoder[String].contramap(_.id.id)
}
