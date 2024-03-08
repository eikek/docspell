/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import cats.effect._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler
import docspell.logging.Logger

object OcrMyPdf {

  def toPDF[F[_]: Async: Files, A](
      cfg: OcrMyPdfConfig,
      lang: Language,
      chunkSize: Int,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] =
    if (cfg.enabled) {
      val reader: (Path, Int) => F[ConversionResult[F]] =
        ExternConv.readResult[F](chunkSize, logger)

      val cmd = cfg.command.withVars(Map("lang" -> lang.iso3))

      ExternConv.toPDF[F, A](
        "ocrmypdf",
        cmd,
        cfg.workingDir,
        useStdin = false,
        logger,
        reader
      )(in, handler)
    } else
      handler(ConversionResult.unsupportedFormat(MimeType.pdf))

}
