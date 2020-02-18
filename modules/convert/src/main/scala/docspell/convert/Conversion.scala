package docspell.convert

import fs2._
import cats.effect._
import docspell.common._

trait Conversion[F[_]] {

  def toPDF[A](in: Stream[F, Byte], dataType: DataType, handler: Pipe[F, Byte, A]): F[ConversionResult[F]]

}

object Conversion {

  def create[F[_]: Sync: ContextShift](cfg: ConvertConfig, blocker: Blocker, logger: Logger[F]): Resource[F, Conversion[F]] =
    Resource.pure(new Conversion[F] {

      def toPDF[A](in: Stream[F, Byte], dataType: DataType, handler: Pipe[F, Byte, A]): F[ConversionResult[F]] = {
        println(s"$cfg $blocker $logger")
        ???
      }

    })
}
