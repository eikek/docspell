package docspell.common

import java.io.IOException
import java.nio.file.attribute.BasicFileAttributes
import java.nio.file.{FileVisitResult, Files, Path, SimpleFileVisitor}
import java.util.concurrent.atomic.AtomicInteger

import scala.jdk.CollectionConverters._
import fs2.Stream
import cats.implicits._
import cats.effect._

object File {

  def mkDir[F[_]: Sync](dir: Path): F[Path] =
    Sync[F].delay(Files.createDirectories(dir))

  def mkTempDir[F[_]: Sync](parent: Path, prefix: String): F[Path] =
    mkDir(parent).map(p => Files.createTempDirectory(p, prefix))

  def mkTempFile[F[_]: Sync](
      parent: Path,
      prefix: String,
      suffix: Option[String] = None
  ): F[Path] =
    mkDir(parent).map(p => Files.createTempFile(p, prefix, suffix.orNull))

  def deleteDirectory[F[_]: Sync](dir: Path): F[Int] =
    Sync[F].delay {
      val count = new AtomicInteger(0)
      Files.walkFileTree(
        dir,
        new SimpleFileVisitor[Path]() {
          override def visitFile(
              file: Path,
              attrs: BasicFileAttributes
          ): FileVisitResult = {
            Files.deleteIfExists(file)
            count.incrementAndGet()
            FileVisitResult.CONTINUE
          }
          override def postVisitDirectory(dir: Path, e: IOException): FileVisitResult =
            Option(e) match {
              case Some(ex) => throw ex
              case None =>
                Files.deleteIfExists(dir)
                FileVisitResult.CONTINUE
            }
        }
      )
      count.get
    }

  def exists[F[_]: Sync](file: Path): F[Boolean] =
    Sync[F].delay(Files.exists(file))

  def existsNonEmpty[F[_]: Sync](file: Path, minSize: Long = 0): F[Boolean] =
    Sync[F].delay(Files.exists(file) && Files.size(file) > minSize)

  def deleteFile[F[_]: Sync](file: Path): F[Unit] =
    Sync[F].delay(Files.deleteIfExists(file)).map(_ => ())

  def delete[F[_]: Sync](path: Path): F[Int] =
    if (Files.isDirectory(path)) deleteDirectory(path)
    else deleteFile(path).map(_ => 1)

  def withTempDir[F[_]: Sync](parent: Path, prefix: String): Resource[F, Path] =
    Resource.make(mkTempDir(parent, prefix))(p => delete(p).map(_ => ()))

  def listFiles[F[_]: Sync](pred: Path => Boolean, dir: Path): F[List[Path]] =
    Sync[F].delay {
      val javaList =
        Files.list(dir).filter(p => pred(p)).collect(java.util.stream.Collectors.toList())
      javaList.asScala.toList.sortBy(_.getFileName.toString)
    }

  def readAll[F[_]: Sync: ContextShift](
      file: Path,
      blocker: Blocker,
      chunkSize: Int
  ): Stream[F, Byte] =
    fs2.io.file.readAll(file, blocker, chunkSize)

  def readText[F[_]: Sync: ContextShift](file: Path, blocker: Blocker): F[String] =
    readAll[F](file, blocker, 8192).through(fs2.text.utf8Decode).compile.foldMonoid
}
