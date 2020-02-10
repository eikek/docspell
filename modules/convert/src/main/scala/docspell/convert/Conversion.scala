package docspell.convert

import fs2._
import cats.effect._
import docspell.common._

trait Conversion[F[_]] {

  def toPDF(inType: MimeType): Pipe[F, Byte, Byte]

}

object Conversion {

  def create[F[_]: Sync](cfg: ConvertConfig): Resource[F, Conversion[F]] =
    Resource.pure(new Conversion[F] {

      def toPDF(inType: MimeType): Pipe[F, Byte, Byte] = {
        println(cfg)
        ???
      }

    })
}
