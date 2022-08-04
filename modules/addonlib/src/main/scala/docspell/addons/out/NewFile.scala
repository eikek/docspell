/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.out

import cats.effect.Sync
import cats.syntax.all._
import fs2.io.file.{Files, Path}
import docspell.addons.out.NewFile.Meta
import docspell.common.ProcessItemArgs.ProcessMeta
import docspell.common.{CollectiveId, Ident, Language}
import docspell.logging.Logger
import io.circe.Codec
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.deriveConfiguredCodec
import io.circe.generic.semiauto.deriveCodec

case class NewFile(metadata: Meta = Meta.empty, file: String) {

  def resolveFile[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path
  ): F[Option[Path]] = {
    val target = outputDir / file
    Files[F]
      .exists(target)
      .flatMap(flag =>
        if (flag) target.some.pure[F]
        else logger.warn(s"File not found: $file").as(Option.empty)
      )
  }
}

object NewFile {

  case class Meta(
      language: Option[Language],
      skipDuplicate: Option[Boolean],
      attachmentsOnly: Option[Boolean]
  ) {

    def toProcessMeta(
        cid: CollectiveId,
        itemId: Ident,
        collLang: Option[Language],
        sourceAbbrev: String
    ): ProcessMeta =
      ProcessMeta(
        collective = cid,
        itemId = Some(itemId),
        language = language.orElse(collLang).getOrElse(Language.English),
        direction = None,
        sourceAbbrev = sourceAbbrev,
        folderId = None,
        validFileTypes = Seq.empty,
        skipDuplicate = skipDuplicate.getOrElse(true),
        fileFilter = None,
        tags = None,
        reprocess = false,
        attachmentsOnly = attachmentsOnly
      )
  }

  object Meta {
    val empty = Meta(None, None, None)
    implicit val jsonCodec: Codec[Meta] = deriveCodec
  }

  implicit val jsonConfig: Configuration = Configuration.default.withDefaults

  implicit val jsonCodec: Codec[NewFile] = deriveConfiguredCodec
}
