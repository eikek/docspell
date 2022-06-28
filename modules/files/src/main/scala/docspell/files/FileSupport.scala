/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import cats.data.OptionT
import cats.effect.{Async, Sync}
import cats.syntax.all._
import fs2.Pipe
import fs2.io.file.{Files, Path}

import docspell.common.{Binary, MimeType, MimeTypeHint}

trait FileSupport {
  implicit final class FileOps(self: Path) {
    def detectMime[F[_]: Files: Sync]: F[Option[MimeType]] =
      Files[F].isReadable(self).flatMap { flag =>
        OptionT
          .whenF(flag) {
            TikaMimetype
              .detect(
                Files[F].readAll(self),
                MimeTypeHint.filename(self.fileName.toString)
              )
          }
          .value
      }

    def mimeType[F[_]: Files: Sync]: F[MimeType] =
      detectMime.map(_.getOrElse(MimeType.octetStream))
  }

  def detectMime[F[_]: Sync]: Pipe[F, Binary[F], Binary[F]] =
    _.evalMap { bin =>
      val hint = MimeTypeHint.filename(bin.name).withAdvertised(bin.mime.asString)
      TikaMimetype.detect[F](bin.data, hint).map(mt => bin.copy(mime = mt))
    }

  def toBinaryWithMime[F[_]: Async]: Pipe[F, Path, Binary[F]] =
    _.evalMap(file => file.mimeType.map(mt => Binary(file).copy(mime = mt)))
}

object FileSupport extends FileSupport
