/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import cats.implicits._
import db.migration.data.FileIntegrityCheckArgs.FileKeyPart
import docspell.common.{FileCategory, Ident}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}
import io.circe.syntax._
import io.circe.DecodingFailure

/** @deprecated `FileKey` and `FileKeyPart` was replaced to use a `CollectiveId` */
final case class FileIntegrityCheckArgs(pattern: FileKeyPart)

object FileIntegrityCheckArgs {
  val taskName: Ident = Ident.unsafe("all-file-integrity-check")

  final case class FileKey(collective: Ident, category: FileCategory, id: Ident) {
    override def toString =
      s"${collective.id}/${category.id.id}/${id.id}"
  }

  object FileKey {

    implicit val jsonDecoder: Decoder[FileKey] =
      deriveDecoder[FileKey]

    implicit val jsonEncoder: Encoder[FileKey] =
      deriveEncoder[FileKey]
  }

  sealed trait FileKeyPart {}

  object FileKeyPart {

    case object Empty extends FileKeyPart

    final case class Collective(collective: Ident) extends FileKeyPart

    final case class Category(collective: Ident, category: FileCategory)
        extends FileKeyPart

    final case class Key(key: FileKey) extends FileKeyPart

    implicit val jsonEncoder: Encoder[FileKeyPart] =
      Encoder.instance {
        case Empty => ().asJson
        case Collective(cid) =>
          Map("collective" -> cid.asJson).asJson
        case Category(cid, cat) =>
          Map("collective" -> cid.asJson, "category" -> cat.asJson).asJson
        case Key(key) =>
          key.asJson
      }

    implicit val jsonDecoder: Decoder[FileKeyPart] =
      Decoder.instance { cursor =>
        for {
          cid <- cursor.getOrElse[Option[Ident]]("collective")(None)
          cat <- cursor.getOrElse[Option[FileCategory]]("category")(None)
          emptyObj = cursor.keys.exists(_.isEmpty)

          c3 = cursor.as[FileKey].map(Key).toOption
          c2 = (cid, cat).mapN(Category)
          c1 = cid.map(Collective)
          c0 = Option.when(emptyObj)(Empty)

          c = c3.orElse(c2).orElse(c1).orElse(c0)
          res <- c.toRight(DecodingFailure("", cursor.history))
        } yield res
      }
  }

  implicit val jsonDecoder: Decoder[FileIntegrityCheckArgs] =
    deriveDecoder

  implicit val jsonEncoder: Encoder[FileIntegrityCheckArgs] =
    deriveEncoder
}
