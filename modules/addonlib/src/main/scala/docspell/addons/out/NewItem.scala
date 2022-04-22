/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.out

import cats.Monad
import cats.syntax.all._
import fs2.io.file.{Files, Path}

import docspell.addons.out.NewItem.Meta
import docspell.common._
import docspell.logging.Logger

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

case class NewItem(metadata: Option[Meta], files: List[String]) {

  def toProcessMeta(
      cid: Ident,
      collLang: Option[Language],
      sourceAbbrev: String
  ): ProcessItemArgs.ProcessMeta =
    metadata
      .getOrElse(Meta(None, None, None, None, None, None, None))
      .toProcessArgs(cid, collLang, sourceAbbrev)

  def resolveFiles[F[_]: Files: Monad](
      logger: Logger[F],
      outputDir: Path
  ): F[List[Path]] = {
    val allFiles =
      files.map(name => outputDir / name)

    allFiles.traverseFilter { file =>
      Files[F]
        .exists(file)
        .flatMap {
          case true => file.some.pure[F]
          case false =>
            logger
              .warn(s"File $file doesn't exist. Ignoring it.")
              .as(None)
        }
    }
  }
}

object NewItem {

  case class Meta(
      language: Option[Language],
      direction: Option[Direction],
      folderId: Option[Ident],
      source: Option[String],
      skipDuplicate: Option[Boolean],
      tags: Option[List[String]],
      attachmentsOnly: Option[Boolean]
  ) {

    def toProcessArgs(
        cid: Ident,
        collLang: Option[Language],
        sourceAbbrev: String
    ): ProcessItemArgs.ProcessMeta =
      ProcessItemArgs.ProcessMeta(
        collective = cid,
        itemId = None,
        language = language.orElse(collLang).getOrElse(Language.English),
        direction = direction,
        sourceAbbrev = source.getOrElse(sourceAbbrev),
        folderId = folderId,
        validFileTypes = Seq.empty,
        skipDuplicate = skipDuplicate.getOrElse(true),
        fileFilter = None,
        tags = tags,
        reprocess = false,
        attachmentsOnly = attachmentsOnly
      )
  }

  object Meta {
    implicit val jsonEncoder: Encoder[Meta] = deriveEncoder
    implicit val jsonDecoder: Decoder[Meta] = deriveDecoder
  }

  implicit val jsonDecoder: Decoder[NewItem] = deriveDecoder
  implicit val jsonEncoder: Encoder[NewItem] = deriveEncoder
}
