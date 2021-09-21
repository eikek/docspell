/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import cats.effect._
import fs2.Stream
import fs2.io.file.Path

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler

object Tesseract {

  def toPDF[F[_]: Async, A](
      cfg: TesseractConfig,
      lang: Language,
      chunkSize: Int,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val outBase = cfg.command.args.tail.headOption.getOrElse("out")
    val reader: (Path, SystemCommand.Result) => F[ConversionResult[F]] =
      ExternConv.readResultTesseract[F](outBase, chunkSize, logger)

    ExternConv.toPDF[F, A](
      "tesseract",
      cfg.command.replace(Map("{{lang}}" -> lang.iso3)),
      cfg.workingDir,
      false,
      logger,
      reader
    )(in, handler)
  }

}
