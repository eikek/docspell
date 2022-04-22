/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import java.io.InputStream
import java.nio.charset.StandardCharsets
import java.util.zip.{ZipEntry, ZipInputStream, ZipOutputStream}

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}
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

  def unzip[F[_]: Async](
      chunkSize: Int,
      glob: Glob
  ): Pipe[F, Byte, Binary[F]] =
    s => unzipStream[F](chunkSize, glob)(s)

  def unzipStream[F[_]: Async](chunkSize: Int, glob: Glob)(
      data: Stream[F, Byte]
  ): Stream[F, Binary[F]] =
    data
      .through(fs2.io.toInputStream[F])
      .flatMap(in => unzipJava(in, chunkSize, glob))

  def saveTo[F[_]: Async](
      logger: Logger[F],
      targetDir: Path,
      moveUp: Boolean
  ): Pipe[F, Binary[F], Path] =
    binaries =>
      binaries
        .filter(e => !e.name.endsWith("/"))
        .evalMap { entry =>
          val out = targetDir / entry.name
          val createParent =
            OptionT
              .fromOption[F](out.parent)
              .flatMapF(parent =>
                Files[F]
                  .exists(parent)
                  .map(flag => Option.when(!flag)(parent))
              )
              .semiflatMap(p => Files[F].createDirectories(p))
              .getOrElse(())

          logger.trace(s"Unzip ${entry.name} -> $out") *>
            createParent *>
            entry.data.through(Files[F].writeAll(out)).compile.drain
        }
        .drain ++ Stream
        .eval(if (moveUp) moveContentsUp(logger)(targetDir) else ().pure[F])
        .as(targetDir)

  private def moveContentsUp[F[_]: Sync: Files](logger: Logger[F])(dir: Path): F[Unit] =
    Files[F]
      .list(dir)
      .take(2)
      .compile
      .toList
      .flatMap {
        case subdir :: Nil =>
          Files[F].isDirectory(subdir).flatMap {
            case false => ().pure[F]
            case true =>
              Files[F]
                .list(subdir)
                .filter(p => p != dir)
                .evalTap(c => logger.trace(s"Move $c -> ${dir / c.fileName}"))
                .evalMap(child => Files[F].move(child, dir / child.fileName))
                .compile
                .drain
          }

        case _ =>
          ().pure[F]
      }

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
        val name = ze.getName()
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
