package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.Stream

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler

object Unoconv {

  def toPDF[F[_]: Async, A](
      cfg: UnoconvConfig,
      chunkSize: Int,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResult[F](chunkSize, logger)

    ExternConv.toPDF[F, A](
      "unoconv",
      cfg.command,
      cfg.workingDir,
      false,
      logger,
      reader
    )(
      in,
      handler
    )
  }

}
