package docspell.text.ocr

import cats.implicits._
import scala.jdk.CollectionConverters._
import java.io.IOException
import java.nio.file.attribute.BasicFileAttributes
import java.nio.file.{FileVisitResult, Files, Path, SimpleFileVisitor}
import java.util.concurrent.atomic.AtomicInteger

import cats.effect.Sync
import fs2.Stream

object File {

  def mkDir[F[_]: Sync](dir: Path): F[Path] =
    Sync[F].delay(Files.createDirectories(dir))

  def mkTempDir[F[_]: Sync](parent: Path, prefix: String): F[Path] =
    mkDir(parent).map(p => Files.createTempDirectory(p, prefix))

  def deleteDirectory[F[_]: Sync](dir: Path): F[Int] = Sync[F].delay {
    val count = new AtomicInteger(0)
    Files.walkFileTree(dir, new SimpleFileVisitor[Path]() {
      override def visitFile(file: Path, attrs: BasicFileAttributes): FileVisitResult = {
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
    })
    count.get
  }

  def deleteFile[F[_]: Sync](file: Path): F[Unit] =
    Sync[F].delay(Files.deleteIfExists(file)).map(_ => ())

  def delete[F[_]: Sync](path: Path): F[Int] =
    if (Files.isDirectory(path)) deleteDirectory(path)
    else deleteFile(path).map(_ => 1)

  def withTempDir[F[_]: Sync, A](parent: Path, prefix: String)
    (f: Path => Stream[F, A]): Stream[F, A] =
    Stream.bracket(mkTempDir(parent, prefix))(p => delete(p).map(_ => ())).flatMap(f)

  def listFiles[F[_]: Sync](pred: Path => Boolean, dir: Path): F[List[Path]] = Sync[F].delay {
    val javaList = Files.list(dir).filter(p => pred(p)).collect(java.util.stream.Collectors.toList())
    javaList.asScala.toList.sortBy(_.getFileName.toString)
  }

}
