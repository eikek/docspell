package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.Stream
import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler

object Tesseract {

  def toPDF[F[_]: Sync: ContextShift, A](
      cfg: TesseractConfig,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val outBase = cfg.cmd.args.tail.headOption.getOrElse("out")
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResultTesseract[F](outBase, blocker, chunkSize, logger)

    ExternConv.toPDF[F, A]("tesseract", cfg.cmd, cfg.workingDir, false, blocker, logger, reader)(in, handler)
  }

}
