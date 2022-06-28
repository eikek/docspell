/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import java.io.BufferedInputStream
import java.nio.charset.StandardCharsets
import java.util.zip.{ZipEntry, ZipFile, ZipOutputStream}

import scala.jdk.CollectionConverters._
import scala.util.Using
import scala.util.Using.Releasable

import cats.effect._
import cats.syntax.all._
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Pipe, Stream}

import docspell.common.Glob
import docspell.logging.Logger

final private class ZipImpl[F[_]: Async](
    log: Option[Logger[F]],
    tempDir: Option[Path]
) extends Zip[F] {
  private[this] val logger = log.getOrElse(docspell.logging.Logger.offF[F])

  private val createTempDir: Resource[F, Path] =
    Files[F].tempDirectory(tempDir, "docspell-zip-", None)

  def zip(chunkSize: Int): Pipe[F, (String, Stream[F, Byte]), Byte] =
    in => ZipImpl.zipJava(logger, chunkSize, in.through(ZipImpl.deduplicate))

  def zipFiles(chunkSize: Int): Pipe[F, (String, Path), Byte] =
    in => ZipImpl.zipJavaPath(logger, chunkSize, in.through(ZipImpl.deduplicate))

  def unzip(
      chunkSize: Int,
      glob: Glob,
      targetDir: Option[Path]
  ): Pipe[F, Byte, Path] = { input =>
    Stream
      .resource(Files[F].tempFile(tempDir, "", ".zip", None))
      .evalTap(tempFile => input.through(Files[F].writeAll(tempFile)).compile.drain)
      .through(unzipFiles(chunkSize, glob, _ => targetDir))
  }

  def unzipFiles(
      chunkSize: Int,
      glob: Glob,
      targetDir: Path => Option[Path]
  ): Pipe[F, Path, Path] =
    input =>
      for {
        zipArchive <- input
        tempDir <- targetDir(zipArchive)
          .map(Stream.emit)
          .getOrElse(Stream.resource(createTempDir))
        entries <- Stream.eval(Sync[F].blocking {
          ZipImpl.unzipZipFile(zipArchive, tempDir, glob)
        })
        e <- Stream.chunk(entries)
      } yield e
}

object ZipImpl {
  implicit val zipFileReleasable: Releasable[ZipFile] =
    (resource: ZipFile) => resource.close()

  private def unzipZipFile(zip: Path, target: Path, glob: Glob): Chunk[Path] =
    Using.resource(new ZipFile(zip.toNioPath.toFile, StandardCharsets.UTF_8)) { zf =>
      Chunk.iterator(
        zf.entries()
          .asScala
          .filter(ze => !ze.getName.endsWith("/"))
          .filter(ze => glob.matchFilenameOrPath(ze.getName))
          .map { ze =>
            val out = target / ze.getName
            out.parent.map(_.toNioPath).foreach { p =>
              java.nio.file.Files.createDirectories(p)
            }
            Using.resource(java.nio.file.Files.newOutputStream(out.toNioPath)) { fout =>
              zf.getInputStream(ze).transferTo(fout)
              out
            }
          }
      )
    }

//  private def unzipZipStream(
//      zip: InputStream,
//      target: Path,
//      glob: Glob
//  ): List[Path] =
//    Using.resource(new ZipInputStream(zip, StandardCharsets.UTF_8)) { zf =>
//      @annotation.tailrec
//      def go(entry: Option[ZipEntry], result: List[Path]): List[Path] =
//        entry match {
//          case Some(ze) if glob.matchFilenameOrPath(ze.getName) =>
//            val out = target / ze.getName
//            Using.resource(java.nio.file.Files.newOutputStream(out.toNioPath)) { fout =>
//              zf.transferTo(fout)
//            }
//            zf.closeEntry()
//            go(Option(zf.getNextEntry), out :: result)
//          case Some(_) =>
//            zf.closeEntry()
//            go(Option(zf.getNextEntry), result)
//          case None =>
//            result
//        }
//
//      go(Option(zf.getNextEntry), Nil)
//    }

//  private def unzipStream2[F[_]: Async](
//      in: InputStream,
//      chunkSize: Int,
//      glob: Glob
//  ): Stream[F, Binary[F]] = {
//    val zin = new ZipInputStream(in)
//
//    val nextEntry = Resource.make(Sync[F].delay(Option(zin.getNextEntry))) {
//      case Some(_) => Sync[F].delay(zin.closeEntry())
//      case None    => ().pure[F]
//    }
//
//    Stream
//      .resource(nextEntry)
//      .repeat
//      .unNoneTerminate
//      .filter(ze => glob.matchFilenameOrPath(ze.getName))
//      .map { ze =>
//        val name = ze.getName
//        val data =
//          fs2.io.readInputStream[F]((zin: InputStream).pure[F], chunkSize, false)
//        Binary(name, data)
//      }
//  }

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

    @annotation.tailrec
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

  private def zipJava[F[_]: Async](
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

  private def zipJavaPath[F[_]: Async](
      logger: Logger[F],
      chunkSize: Int,
      entries: Stream[F, (String, Path)]
  ): Stream[F, Byte] =
    fs2.io.readOutputStream(chunkSize) { out =>
      val zip = new ZipOutputStream(out, StandardCharsets.UTF_8)
      val writeEntries =
        entries.evalMap { case (name, file) =>
          val javaOut = Sync[F].blocking {
            val fin = new BufferedInputStream(
              java.nio.file.Files.newInputStream(file.toNioPath),
              chunkSize
            )
            fin.transferTo(zip)
            fin.close()
          }

          val nextEntry =
            logger.debug(s"Adding $name to zip file…") *>
              Sync[F].delay(zip.putNextEntry(new ZipEntry(name)))
          Resource
            .make(nextEntry)(_ => Sync[F].delay(zip.closeEntry()))
            .use(_ => javaOut)
        }
      val closeStream = Sync[F].delay(zip.close())

      writeEntries.onFinalize(closeStream).compile.drain
    }
}
