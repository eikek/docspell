package docspell.restserver

import cats.effect._
import cats.implicits._

import scala.concurrent.ExecutionContext
import java.nio.file.{Files, Paths}

import docspell.common.{Banner, ThreadFactories}
import org.log4s._

object Main extends IOApp {
  private[this] val logger = getLogger

  val blockingEC = ThreadFactories.cached[IO](ThreadFactories.ofName("docspell-restserver-blocking"))
  val connectEC = ThreadFactories.fixed[IO](5, ThreadFactories.ofName("docspell-dbconnect"))

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
            } else {
              logger.info(s"Using config file from system properties: $f")
            }
          case _ =>
        }
    }

    val cfg = ConfigFile.loadConfig
    val banner = Banner(
      "REST Server",
      BuildInfo.version,
      BuildInfo.gitHeadCommit,
      cfg.backend.jdbc.url,
      Option(System.getProperty("config.file")),
      cfg.appId,
      cfg.baseUrl
    )
    val pools = for {
      cec <- connectEC
      bec <- blockingEC
      blocker = Blocker.liftExecutorService(bec)
    } yield Pools(cec, bec, blocker)

    logger.info(s"\n${banner.render("***>")}")
    pools.use(p =>
      RestServer.stream[IO](cfg, p.connectEC, p.clientEC, p.blocker).compile.drain.as(ExitCode.Success)
    )
  }

  case class Pools(connectEC: ExecutionContext, clientEC: ExecutionContext, blocker: Blocker)
}
