/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import java.io.InputStream
import java.nio.charset.StandardCharsets
import java.nio.file.Paths
import java.util.zip.{ZipEntry, ZipInputStream, ZipOutputStream}

import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}

import docspell.common.Binary
import docspell.common.Glob
import docspell.logging.Logger

object Zip {

  def zip[F[_]: Async](
      logger: Logger[F],
      chunkSize: Int
  ): Pipe[F, (String, Stream[F, Byte]), Byte] =
    in => zipJava(logger, chunkSize, in.through(deduplicate))

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

  private def deduplicate[F[_]: Sync, A]: Pipe[F, (String, A), (String, A)] = {
    def makeName(name: String, count: Int): String =
      if (count <= 0) name
      else
        name.lastIndexOf('.') match {
          case n if n > 0 =>
            s"${name.substring(0, n)}_$count${name.substring(n)}"
          case _ =>
            s"${name}_$count"
        }

    def unique(
        current: Set[String],
        name: String,
        counter: Int
    ): (Set[String], String) = {
      val nextName = makeName(name, counter)
      if (current.contains(nextName))
        unique(current, name, counter + 1)
      else (current + nextName, nextName)
    }

    in =>
      Stream
        .eval(Ref.of[F, Set[String]](Set.empty[String]))
        .flatMap { ref =>
          in.evalMap { element =>
            ref
              .modify(names => unique(names, element._1, 0))
              .map(n => (n, element._2))
          }
        }
  }

  def zipJava[F[_]: Async](
      logger: Logger[F],
      chunkSize: Int,
      entries: Stream[F, (String, Stream[F, Byte])]
  ): Stream[F, Byte] =
    fs2.io.readOutputStream(chunkSize) { out =>
      val zip = new ZipOutputStream(out, StandardCharsets.UTF_8)
      val writeEntries =
        entries.evalMap { case (name, bytes) =>
          val javaOut =
            bytes.through(
              fs2.io.writeOutputStream[F](Sync[F].pure(zip), closeAfterUse = false)
            )
          val nextEntry =
            logger.debug(s"Adding $name to zip file…") *>
              Sync[F].delay(zip.putNextEntry(new ZipEntry(name)))
          Resource
            .make(nextEntry)(_ => Sync[F].delay(zip.closeEntry()))
            .use(_ => javaOut.compile.drain)
        }
      val closeStream = Sync[F].delay(zip.close())

      writeEntries.onFinalize(closeStream).compile.drain
    }
}
