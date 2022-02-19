/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect._

import docspell.common._
import docspell.logging.impl.ScribeConfigure

object Main extends IOApp {

  private val connectEC =
    ThreadFactories.fixed[IO](5, ThreadFactories.ofName("docspell-dbconnect"))

  def run(args: List[String]) = for {
    cfg <- ConfigFile.loadConfig[IO](args)
    _ <- ScribeConfigure.configure[IO](cfg.logging)
    logger = docspell.logging.getLogger[IO]
    banner = Banner(
      "REST Server",
      BuildInfo.version,
      BuildInfo.gitHeadCommit,
      cfg.backend.jdbc.url,
      Option(System.getProperty("config.file")),
      cfg.appId,
      cfg.baseUrl,
      Some(cfg.fullTextSearch.solr.url).filter(_ => cfg.fullTextSearch.enabled)
    )
    _ <- logger.info(s"\n${banner.render("***>")}")
    _ <-
      if (EnvMode.current.isDev) {
        logger.warn(">>>>>   Docspell is running in DEV mode!   <<<<<")
      } else IO(())

    pools = connectEC.map(Pools.apply)
    rc <-
      pools.use(p => RestServer.serve[IO](cfg, p))
  } yield rc
}
