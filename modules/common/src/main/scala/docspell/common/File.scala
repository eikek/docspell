package docspell.common

import java.io.IOException
import java.nio.file.attribute.BasicFileAttributes
import java.nio.file.{Files => JFiles, _}
import java.util.concurrent.atomic.AtomicInteger

import scala.jdk.CollectionConverters._

import cats.effect._
import cats.implicits._
import fs2.io.file.Files
import fs2.{Chunk, Stream}

import docspell.common.syntax.all._

import io.circe.Decoder
import scodec.bits.ByteVector
//TODO use io.fs2.files.Files api
object File {

  def mkDir[F[_]: Sync](dir: Path): F[Path] =
    Sync[F].blocking(JFiles.createDirectories(dir))

  def mkTempDir[F[_]: Sync](parent: Path, prefix: String): F[Path] =
    mkDir(parent).map(p => JFiles.createTempDirectory(p, prefix))

  def mkTempFile[F[_]: Sync](
      parent: Path,
      prefix: String,
      suffix: Option[String] = None
  ): F[Path] =
    mkDir(parent).map(p => JFiles.createTempFile(p, prefix, suffix.orNull))

  def deleteDirectory[F[_]: Sync](dir: Path): F[Int] =
    Sync[F].delay {
      val count = new AtomicInteger(0)
      JFiles.walkFileTree(
        dir,
        new SimpleFileVisitor[Path]() {
          override def visitFile(
              file: Path,
              attrs: BasicFileAttributes
          ): FileVisitResult = {
            JFiles.deleteIfExists(file)
            count.incrementAndGet()
            FileVisitResult.CONTINUE
          }
          override def postVisitDirectory(dir: Path, e: IOException): FileVisitResult =
            Option(e) match {
              case Some(ex) => throw ex
              case None =>
                JFiles.deleteIfExists(dir)
                FileVisitResult.CONTINUE
            }
        }
      )
      count.get
    }

  def exists[F[_]: Sync](file: Path): F[Boolean] =
    Sync[F].delay(JFiles.exists(file))

  def size[F[_]: Sync](file: Path): F[Long] =
    Sync[F].delay(JFiles.size(file))

  def existsNonEmpty[F[_]: Sync](file: Path, minSize: Long = 0): F[Boolean] =
    Sync[F].delay(JFiles.exists(file) && JFiles.size(file) > minSize)

  def deleteFile[F[_]: Sync](file: Path): F[Unit] =
    Sync[F].delay(JFiles.deleteIfExists(file)).map(_ => ())

  def delete[F[_]: Sync](path: Path): F[Int] =
    if (JFiles.isDirectory(path)) deleteDirectory(path)
    else deleteFile(path).map(_ => 1)

  def withTempDir[F[_]: Sync](parent: Path, prefix: String): Resource[F, Path] =
    Resource.make(mkTempDir(parent, prefix))(p => delete(p).map(_ => ()))

  def listJFiles[F[_]: Sync](pred: Path => Boolean, dir: Path): F[List[Path]] =
    Sync[F].delay {
      val javaList =
        JFiles
          .list(dir)
          .filter(p => pred(p))
          .collect(java.util.stream.Collectors.toList())
      javaList.asScala.toList.sortBy(_.getFileName.toString)
    }

  def readAll[F[_]: Files](
      file: Path,
      chunkSize: Int
  ): Stream[F, Byte] =
    Files[F].readAll(file, chunkSize)

  def readText[F[_]: Files: Concurrent](file: Path): F[String] =
    readAll[F](file, 8192).through(fs2.text.utf8Decode).compile.foldMonoid

  def writeString[F[_]: Files: Concurrent](file: Path, content: String): F[Path] =
    ByteVector.encodeUtf8(content) match {
      case Right(bv) =>
        Stream
          .chunk(Chunk.byteVector(bv))
          .through(Files[F].writeAll(file))
          .compile
          .drain
          .map(_ => file)
      case Left(ex) =>
        Concurrent[F].raiseError(ex)
    }

  def readJson[F[_]: Async, A](file: Path)(implicit d: Decoder[A]): F[A] =
    readText[F](file).map(_.parseJsonAs[A]).rethrow

}
