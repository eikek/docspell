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

  def unzipP[F[_]: ConcurrentEffect: ContextShift](
      chunkSize: Int,
      blocker: Blocker,
      glob: Glob
  ): Pipe[F, Byte, Binary[F]] =
    s => unzip[F](chunkSize, blocker, glob)(s)

  def unzip[F[_]: ConcurrentEffect: ContextShift](
      chunkSize: Int,
      blocker: Blocker,
      glob: Glob
  )(
      data: Stream[F, Byte]
  ): Stream[F, Binary[F]] =
    data
      .through(fs2.io.toInputStream[F])
      .flatMap(in => unzipJava(in, chunkSize, blocker, glob))

  def unzipJava[F[_]: Sync: ContextShift](
      in: InputStream,
      chunkSize: Int,
      blocker: Blocker,
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
          fs2.io.readInputStream[F]((zin: InputStream).pure[F], chunkSize, blocker, false)
        Binary(name, data)
      }
  }
}
