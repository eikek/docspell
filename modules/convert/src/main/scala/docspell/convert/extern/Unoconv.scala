/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import cats.effect._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.Handler
import docspell.logging.Logger

object Unoconv {

  def toPDF[F[_]: Async: Files, A](
      cfg: UnoconvConfig,
      chunkSize: Int,
      logger: Logger[F]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] = {
    val reader: (Path, Int) => F[ConversionResult[F]] =
      ExternConv.readResult[F](chunkSize, logger)

    val serverArgs =
      if (cfg.host.trim.isEmpty) Seq.empty
      else
        Seq(
          "--host",
          cfg.host.trim,
          "--port",
          cfg.port.toString,
          "--host-location",
          "remote"
        )

    val cmd = cfg.command.copy(args = serverArgs ++ cfg.command.args).withVars(Map.empty)

    ExternConv.toPDF[F, A](
      "unoconvert",
      cmd,
      cfg.workingDir,
      useStdin = false,
      logger,
      reader
    )(
      in,
      handler
    )
  }
}
