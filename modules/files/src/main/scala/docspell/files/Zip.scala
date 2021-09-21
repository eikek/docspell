/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import java.io.InputStream
import java.nio.file.Paths
import java.util.zip.ZipInputStream

import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}

import docspell.common.Binary
import docspell.common.Glob

object Zip {

  def unzipP[F[_]: Async](chunkSize: Int, glob: Glob): Pipe[F, Byte, Binary[F]] =
    s => unzip[F](chunkSize, glob)(s)

  def unzip[F[_]: Async](chunkSize: Int, glob: Glob)(
      data: Stream[F, Byte]
  ): Stream[F, Binary[F]] =
    data
      .through(fs2.io.toInputStream[F])
      .flatMap(in => unzipJava(in, chunkSize, glob))

  def unzipJava[F[_]: Async](
      in: InputStream,
      chunkSize: Int,
      glob: Glob
  ): Stream[F, Binary[F]] = {
    val zin = new ZipInputStream(in)

    val nextEntry = Resource.make(Sync[F].delay(Option(zin.getNextEntry))) {
      case Some(_) => Sync[F].delay(zin.closeEntry())
      case None    => ().pure[F]
    }

    Stream
      .resource(nextEntry)
      .repeat
      .unNoneTerminate
      .filter(ze => glob.matchFilenameOrPath(ze.getName()))
      .map { ze =>
        val name = Paths.get(ze.getName()).getFileName.toString
        val data =
          fs2.io.readInputStream[F]((zin: InputStream).pure[F], chunkSize, false)
        Binary(name, data)
      }
  }
}
