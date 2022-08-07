/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import ProcessItemArgs._
import docspell.common.{FileIntegrityCheckArgs => _, _}
import docspell.common.syntax.all._

import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the process-item task.
  *
  * This task is run for each new file to create a new item from it or to add this file as
  * an attachment to an existing item.
  *
  * If the `itemId` is set to some value, the item is tried to load to amend with the
  * given files. Otherwise a new item is created.
  *
  * It is also re-used by the 'ReProcessItem' task.
  *
  * @deprecated
  *   This is an old structure where the collective id was an `Ident` which is now the
  *   collective name. It is used to migrate database records to the new structure (same
  *   name in commons package)
  */
case class ProcessItemArgs(meta: ProcessMeta, files: List[File]) {

  def makeSubject: String =
    files.flatMap(_.name) match {
      case Nil             => s"${meta.sourceAbbrev}: No files supplied"
      case n :: Nil        => n
      case n1 :: n2 :: Nil => s"$n1, $n2"
      case _               => s"${files.size} files from ${meta.sourceAbbrev}"
    }

  def isNormalProcessing: Boolean =
    !meta.reprocess
}

object ProcessItemArgs {

  val taskName = Ident.unsafe("process-item")

  val multiUploadTaskName = Ident.unsafe("multi-upload-process")

  case class ProcessMeta(
      collective: Ident,
      itemId: Option[Ident],
      language: Language,
      direction: Option[Direction],
      sourceAbbrev: String,
      folderId: Option[Ident],
      validFileTypes: Seq[MimeType],
      skipDuplicate: Boolean,
      fileFilter: Option[Glob],
      tags: Option[List[String]],
      reprocess: Boolean,
      attachmentsOnly: Option[Boolean]
  )

  object ProcessMeta {
    implicit val jsonEncoder: Encoder[ProcessMeta] = deriveEncoder[ProcessMeta]
    implicit val jsonDecoder: Decoder[ProcessMeta] = deriveDecoder[ProcessMeta]
  }

  case class File(name: Option[String], fileMetaId: FileIntegrityCheckArgs.FileKey)
  object File {
    implicit val jsonEncoder: Encoder[File] = deriveEncoder[File]
    implicit val jsonDecoder: Decoder[File] = deriveDecoder[File]
  }

  implicit val jsonEncoder: Encoder[ProcessItemArgs] = deriveEncoder[ProcessItemArgs]
  implicit val jsonDecoder: Decoder[ProcessItemArgs] = deriveDecoder[ProcessItemArgs]

  def parse(str: String): Either[Throwable, ProcessItemArgs] =
    str.parseJsonAs[ProcessItemArgs]
}
