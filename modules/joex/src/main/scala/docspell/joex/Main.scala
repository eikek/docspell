/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect._

import docspell.common._
import docspell.logging.Logger
import docspell.logging.impl.ScribeConfigure

object Main extends IOApp {

  private val logger: Logger[IO] = docspell.logging.getLogger[IO]

  private val connectEC =
    ThreadFactories.fixed[IO](5, ThreadFactories.ofName("docspell-joex-dbconnect"))

  def run(args: List[String]): IO[ExitCode] =
    for {
      cfg <- ConfigFile.loadConfig[IO](args)
      _ <- ScribeConfigure.configure[IO](cfg.logging)
      banner = Banner(
        "JOEX",
        BuildInfo.version,
        BuildInfo.gitHeadCommit,
        cfg.jdbc.url,
        Option(System.getProperty("config.file")),
        cfg.appId,
        cfg.baseUrl,
        Some(cfg.fullTextSearch.solr.url).filter(_ => cfg.fullTextSearch.enabled),
        cfg.files.defaultStoreConfig
      )
      _ <- logger.info(s"\n${banner.render("***>")}")
      _ <-
        if (EnvMode.current.isDev) {
          logger.warn(">>>>>   Docspell is running in DEV mode!   <<<<<")
        } else IO(())

      pools = connectEC.map(Pools.apply)
      rc <- pools.use(p =>
        JoexServer
          .stream[IO](cfg, p)
          .compile
          .drain
          .as(ExitCode.Success)
      )
    } yield rc
}
