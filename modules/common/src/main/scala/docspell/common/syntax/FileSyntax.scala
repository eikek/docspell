/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.syntax

import java.nio.file.{Files => NioFiles}

import cats.effect._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common.syntax.stream._

import io.circe.Encoder
import io.circe.syntax._

trait FileSyntax {

  implicit final class PathOps(self: Path) {

    def absolutePath: Path =
      self.absolute

    def absolutePathAsString: String =
      absolutePath.toString

    def name: String = self.fileName.toString
    def extension: String = self.extName.stripPrefix(".")
    def dropLeft(n: Int): Path =
      Path.fromNioPath(self.toNioPath.subpath(n, self.toNioPath.getNameCount))

    def readString[F[_]: Sync]: F[String] = Sync[F].blocking(
      NioFiles.readString(self.toNioPath)
    )

    def sha256Hex[F[_]: Files: Sync]: F[String] =
      Files[F].readAll(self).sha256Hex

    def readAll[F[_]: Files]: Stream[F, Byte] =
      Files[F].readAll(self)

    def writeJson[A: Encoder, F[_]: Files: Sync](value: A): F[Unit] =
      Stream
        .emit(value.asJson.noSpaces)
        .through(fs2.text.utf8.encode)
        .through(Files[F].writeAll(self))
        .compile
        .drain
  }
}

object FileSyntax extends FileSyntax
