/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import java.nio.charset.Charset

import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}
import fs2.{Chunk, Stream}

import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.convert.{ConversionResult, SanitizeHtml}
import docspell.logging.Logger

object WkHtmlPdf {

  def toPDF[F[_]: Async: Files, A](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      charset: Charset,
      sanitizeHtml: SanitizeHtml,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, Int) => F[ConversionResult[F]] =
      ExternConv.readResult[F](chunkSize, logger)

    val cmdCfg = cfg.command.withVars(Map("encoding" -> charset.name()))

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
      .toPDF[F, A](
        "wkhtmltopdf",
        cmdCfg,
        cfg.workingDir,
        useStdin = true,
        logger,
        reader
      )(
        inSane,
        handler
      )
  }
}
