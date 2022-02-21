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

object ScribeConfigure {
  private[this] val docspellRootVerbose = "DOCSPELL_ROOT_LOGGER_LEVEL"

  def configure[F[_]: Sync](cfg: LogConfig): F[Unit] =
    Sync[F].delay {
      replaceJUL()
      val docspellLogger = scribe.Logger("docspell")
      unsafeConfigure(scribe.Logger.root, cfg.copy(minimumLevel = getRootMinimumLevel))
      unsafeConfigure(docspellLogger, cfg)
    }

  private[this] def getRootMinimumLevel: Level =
    Option(System.getenv(docspellRootVerbose))
      .map(Level.fromString)
      .flatMap {
        case Right(level) => Some(level)
        case Left(err) =>
          scribe.warn(
            s"Environment variable '$docspellRootVerbose' has invalid value: $err"
          )
          None
      }
      .getOrElse(Level.Error)

  def unsafeConfigure(logger: scribe.Logger, cfg: LogConfig): Unit = {
    val mods = List[scribe.Logger => scribe.Logger](
      _.clearHandlers(),
      _.withMinimumLevel(ScribeWrapper.convertLevel(cfg.minimumLevel)),
      l =>
        cfg.format match {
          case Format.Fancy =>
            l.withHandler(formatter = Formatter.enhanced, writer = StdoutWriter)
          case Format.Plain =>
            l.withHandler(formatter = Formatter.classic, writer = StdoutWriter)
          case Format.Json =>
            l.withHandler(writer = JsonWriter(StdoutWriter))
          case Format.Logfmt =>
            l.withHandler(writer = LogfmtWriter(StdoutWriter))
        },
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
