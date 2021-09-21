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
