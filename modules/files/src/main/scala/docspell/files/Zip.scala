package docspell.files

import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}
import java.io.InputStream
import java.util.zip.ZipInputStream
import java.nio.file.Paths
import docspell.common.Binary

object Zip {

  def unzipP[F[_]: ConcurrentEffect: ContextShift](
      chunkSize: Int,
      blocker: Blocker
  ): Pipe[F, Byte, Binary[F]] =
    s => unzip[F](chunkSize, blocker)(s)

  def unzip[F[_]: ConcurrentEffect: ContextShift](chunkSize: Int, blocker: Blocker)(
      data: Stream[F, Byte]
  ): Stream[F, Binary[F]] =
    data.through(fs2.io.toInputStream[F]).flatMap(in => unzipJava(in, chunkSize, blocker))

  def unzipJava[F[_]: Sync: ContextShift](
      in: InputStream,
      chunkSize: Int,
      blocker: Blocker
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
      .map { ze =>
        val name = Paths.get(ze.getName()).getFileName.toString
        val data =
          fs2.io.readInputStream[F]((zin: InputStream).pure[F], chunkSize, blocker, false)
        Binary(name, data)
      }
  }
}
