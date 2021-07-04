/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex

import java.nio.file.{Files, Paths}

import cats.effect._
import cats.implicits._

import docspell.common._

import org.log4s._

object Main extends IOApp {
  private[this] val logger = getLogger

  val blockingEC =
    ThreadFactories.cached[IO](ThreadFactories.ofName("docspell-joex-blocking"))
  val connectEC =
    ThreadFactories.fixed[IO](5, ThreadFactories.ofName("docspell-joex-dbconnect"))
  val restserverEC =
    ThreadFactories.workSteal[IO](ThreadFactories.ofNameFJ("docspell-joex-server"))

  def run(args: List[String]) = {
    args match {
      case file :: Nil =>
        val path = Paths.get(file).toAbsolutePath.normalize
        logger.info(s"Using given config file: $path")
        System.setProperty("config.file", file)
      case _ =>
        Option(System.getProperty("config.file")) match {
          case Some(f) if f.nonEmpty =>
            val path = Paths.get(f).toAbsolutePath.normalize
            if (!Files.exists(path)) {
              logger.info(s"Not using config file '$f' because it doesn't exist")
              System.clearProperty("config.file")
            } else
              logger.info(s"Using config file from system properties: $f")
          case _ =>
        }
    }

    val cfg = ConfigFile.loadConfig
    val banner = Banner(
      "JOEX",
      BuildInfo.version,
      BuildInfo.gitHeadCommit,
      cfg.jdbc.url,
      Option(System.getProperty("config.file")),
      cfg.appId,
      cfg.baseUrl,
      Some(cfg.fullTextSearch.solr.url).filter(_ => cfg.fullTextSearch.enabled)
    )
    logger.info(s"\n${banner.render("***>")}")
    if (EnvMode.current.isDev) {
      logger.warn(">>>>>   Docspell is running in DEV mode!   <<<<<")
    }

    val pools = for {
      cec <- connectEC
      bec <- blockingEC
      rec <- restserverEC
    } yield Pools(cec, bec, rec)
    pools.use(p =>
      JoexServer
        .stream[IO](cfg, p)
        .compile
        .drain
        .as(ExitCode.Success)
    )
  }
}
