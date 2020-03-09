package docspell.joex

import cats.effect.{Blocker, ExitCode, IO, IOApp}
import cats.implicits._

import scala.concurrent.ExecutionContext
import java.util.concurrent.Executors
import java.nio.file.{Files, Paths}

import docspell.common.{Banner, ThreadFactories}
import org.log4s._

object Main extends IOApp {
  private[this] val logger = getLogger

  val blockingEC: ExecutionContext = ExecutionContext.fromExecutor(
    Executors.newCachedThreadPool(ThreadFactories.ofName("docspell-joex-blocking"))
  )
  val blocker = Blocker.liftExecutionContext(blockingEC)
  val connectEC: ExecutionContext = ExecutionContext.fromExecutorService(
    Executors.newFixedThreadPool(5, ThreadFactories.ofName("docspell-joex-dbconnect"))
  )

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
      "JOEX",
      BuildInfo.version,
      BuildInfo.gitHeadCommit,
      cfg.jdbc.url,
      Option(System.getProperty("config.file")),
      cfg.appId,
      cfg.baseUrl
    )
    logger.info(s"\n${banner.render("***>")}")
    JoexServer.stream[IO](cfg, connectEC, blockingEC, blocker).compile.drain.as(ExitCode.Success)
  }
}
