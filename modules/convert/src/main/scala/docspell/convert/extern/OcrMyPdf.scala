package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.Stream

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler

object OcrMyPdf {

  def toPDF[F[_]: Async, A](
      cfg: OcrMyPdfConfig,
      lang: Language,
      chunkSize: Int,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] =
    if (cfg.enabled) {
      val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
        ExternConv.readResult[F](chunkSize, logger)

      ExternConv.toPDF[F, A](
        "ocrmypdf",
        cfg.command.replace(Map("{{lang}}" -> lang.iso3)),
        cfg.workingDir,
        false,
        logger,
        reader
      )(in, handler)
    } else
      handler(ConversionResult.unsupportedFormat(MimeType.pdf))

}
