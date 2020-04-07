package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}
import docspell.common._
import docspell.convert.{ConversionResult, SanitizeHtml}
import docspell.convert.ConversionResult.Handler
import java.nio.charset.Charset

object WkHtmlPdf {

  def toPDF[F[_]: Sync: ContextShift, A](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      charset: Charset,
      sanitizeHtml: SanitizeHtml,
      blocker: Blocker,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResult[F](blocker, chunkSize, logger)

    val cmdCfg = cfg.command.replace(Map("{{encoding}}" -> charset.name()))

    // html sanitize should (among other) remove links to invalid
    // protocols like cid: which is not supported by further
    // processing (wkhtmltopdf errors)
    //
    // Since jsoup will load everything anyways, a stream-based
    // conversion to java's inputstream doesn't make much sense.
    val inSane = Stream.evalUnChunk(
      Binary
        .loadAllBytes(in)
        .map(bv => sanitizeHtml(bv, charset.some))
        .map(bv => Chunk.byteVector(bv))
    )

    ExternConv
      .toPDF[F, A]("wkhtmltopdf", cmdCfg, cfg.workingDir, true, blocker, logger, reader)(
        inSane,
        handler
      )
  }

}
