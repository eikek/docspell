package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.Stream
import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler
import java.nio.charset.Charset

object WkHtmlPdf {

  def toPDF[F[_]: Sync: ContextShift, A](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      charset: Charset,
      blocker: Blocker,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResult[F](blocker, chunkSize, logger)

    val cmdCfg = cfg.command.replace(Map("{{encoding}}" -> charset.name()))
    ExternConv
      .toPDF[F, A]("wkhtmltopdf", cmdCfg, cfg.workingDir, true, blocker, logger, reader)(
        in,
        handler
      )
  }

}
