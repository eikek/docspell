/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import cats.effect._
import fs2.io.file.Path
import fs2.{Pipe, Stream}

import docspell.common.Glob
import docspell.logging.Logger

trait Zip[F[_]] {

  def zip(chunkSize: Int = Zip.defaultChunkSize): Pipe[F, (String, Stream[F, Byte]), Byte]

  def zipFiles(chunkSize: Int = Zip.defaultChunkSize): Pipe[F, (String, Path), Byte]

  def unzip(
      chunkSize: Int = Zip.defaultChunkSize,
      glob: Glob = Glob.all,
      targetDir: Option[Path] = None
  ): Pipe[F, Byte, Path]

  def unzipFiles(
      chunkSize: Int = Zip.defaultChunkSize,
      glob: Glob = Glob.all,
      targetDir: Path => Option[Path] = _ => None
  ): Pipe[F, Path, Path]
}

object Zip {
  val defaultChunkSize = 64 * 1024

  def apply[F[_]: Async](
      logger: Option[Logger[F]] = None,
      tempDir: Option[Path] = None
  ): Zip[F] =
    new ZipImpl[F](logger, tempDir)
}
