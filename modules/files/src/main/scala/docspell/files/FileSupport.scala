/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import cats.data.OptionT
import cats.effect.Sync
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common.{MimeType, MimeTypeHint}

import io.circe.Encoder
import io.circe.syntax._

trait FileSupport {
  implicit final class FileOps[F[_]: Files: Sync](self: Path) {
    def detectMime: F[Option[MimeType]] =
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

    def asTextFile(alt: MimeType => F[Unit]): F[Option[Path]] =
      OptionT(detectMime).flatMapF { mime =>
        if (mime.matches(MimeType.text("plain"))) self.some.pure[F]
        else alt(mime).as(None: Option[Path])
      }.value

    def readText: F[String] =
      Files[F]
        .readAll(self)
        .through(fs2.text.utf8.decode)
        .compile
        .string

    def readAll: Stream[F, Byte] =
      Files[F].readAll(self)

    def writeJson[A: Encoder](value: A): F[Unit] =
      Stream
        .emit(value.asJson.noSpaces)
        .through(fs2.text.utf8.encode)
        .through(Files[F].writeAll(self))
        .compile
        .drain
  }
}

object FileSupport extends FileSupport
