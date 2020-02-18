package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.Stream
import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler

object WkHtmlPdf {

  def toPDF[F[_]: Sync: ContextShift, A](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F],
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResult[F](blocker, chunkSize, logger)

    ExternConv.toPDF[F, A]("wkhtmltopdf", cfg.cmd, cfg.workingDir, true, blocker, logger, reader)(in, handler)
  }

}
