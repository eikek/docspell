/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import cats.effect.Sync

import docspell.logging.LogConfig.Format
import docspell.logging.{Level, LogConfig}

import scribe.format.Formatter
import scribe.jul.JULHandler
import scribe.writer.SystemOutWriter

object ScribeConfigure {
  def configure[F[_]: Sync](cfg: LogConfig): F[Unit] =
    Sync[F].delay {
      replaceJUL()
      unsafeConfigure(cfg)
    }

  def unsafeConfigure(cfg: LogConfig): Unit = {
    unsafeConfigure(scribe.Logger.root, cfg.format, cfg.minimumLevel)
    cfg.levels.foreach { case (name, level) =>
      unsafeConfigure(scribe.Logger(name), cfg.format, level)
    }
  }

  def unsafeConfigure(logger: String, cfg: LogConfig): Unit = {
    val log = scribe.Logger(logger)
    val level = cfg.levels.getOrElse(logger, cfg.minimumLevel)
    unsafeConfigure(log, cfg.format, level)
  }

  def unsafeConfigure(
      logger: scribe.Logger,
      format: LogConfig.Format,
      level: Level
  ): Unit = {
    val mods = List[scribe.Logger => scribe.Logger](
      _.clearHandlers(),
      _.withMinimumLevel(ScribeWrapper.convertLevel(level)),
      l =>
        if (logger.id == scribe.Logger.RootId) {
          format match {
            case Format.Fancy =>
              l.withHandler(formatter = Formatter.enhanced, writer = SystemOutWriter)
            case Format.Plain =>
              l.withHandler(formatter = Formatter.classic, writer = SystemOutWriter)
            case Format.Json =>
              l.withHandler(writer = JsonWriter(SystemOutWriter))
            case Format.Logfmt =>
              l.withHandler(writer = LogfmtWriter(SystemOutWriter))
          }
        } else l,
      _.replace()
    )

    mods.foldLeft(logger)((l, mod) => mod(l))
    ()
  }

  private def replaceJUL(): Unit = {
    scribe.Logger.system // just to load effects in Logger singleton
    val julRoot = java.util.logging.LogManager.getLogManager.getLogger("")
    julRoot.getHandlers.foreach(julRoot.removeHandler)
    julRoot.addHandler(JULHandler)
  }
}
