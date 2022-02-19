/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import cats.effect._

import docspell.logging.LogConfig
import docspell.logging.LogConfig.Format

import scribe.format.Formatter
import scribe.jul.JULHandler
import scribe.writer.ConsoleWriter

object ScribeConfigure {

  def configure[F[_]: Sync](cfg: LogConfig): F[Unit] =
    Sync[F].delay {
      replaceJUL()
      unsafeConfigure(scribe.Logger.root, cfg)
    }

  def unsafeConfigure(logger: scribe.Logger, cfg: LogConfig): Unit = {
    val mods = List[scribe.Logger => scribe.Logger](
      _.clearHandlers(),
      _.withMinimumLevel(LoggerWrapper.convertLevel(cfg.minimumLevel)),
      l =>
        cfg.format match {
          case Format.Fancy =>
            l.withHandler(formatter = Formatter.enhanced)
          case Format.Plain =>
            l.withHandler(formatter = Formatter.classic)
          case Format.Json =>
            l.withHandler(writer = JsonWriter(ConsoleWriter))
          case Format.Logfmt =>
            l.withHandler(writer = LogfmtWriter(ConsoleWriter))
        },
      _.replace()
    )

    mods.foldLeft(logger)((l, mod) => mod(l))
    ()
  }

  def replaceJUL(): Unit = {
    scribe.Logger.system // just to load effects in Logger singleton
    val julRoot = java.util.logging.LogManager.getLogManager.getLogger("")
    julRoot.getHandlers.foreach(julRoot.removeHandler)
    julRoot.addHandler(JULHandler)
  }
}
