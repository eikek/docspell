package docspell.build

import sbt._
import sbt.Keys._
import scala.sys.process._

object ZolaPlugin extends AutoPlugin {

  object autoImport {
    val zolaRootDir   = settingKey[File]("The root directory of zola")
    val zolaOutputDir = settingKey[File]("The directory to put the final site")
    val zolaCommand   = settingKey[String]("The zola executable")
    val zolaTestBaseUrl =
      settingKey[String]("The base-url to use when building the test site.")

    val zolaBuild = taskKey[Unit](
      "Build the site using zola, which is then available in 'zolaOutputDir'."
    )
    val zolaBuildTest = taskKey[Unit](
      "Build the site using zola, which is then available in 'zolaOutputDir'. " +
        "It uses a different base-url. So the final site can be tested using " +
        "'python -m SimpleHTTPServer 1234' for example."
    )
    val zolaCheck = taskKey[Unit]("Runs zola check to check links")
  }

  import autoImport._

  def zolaSettings: Seq[Setting[_]] =
    Seq(
      zolaRootDir := baseDirectory.value / "site",
      zolaOutputDir := target.value / "zola-site",
      zolaCommand := "zola",
      zolaTestBaseUrl := "http://localhost:1234",
      zolaBuild := {
        val logger = streams.value.log
        logger.info("Building web site using zola ...")
        (Compile/resources).value
        buildSite(zolaCommand.value, zolaRootDir.value, zolaOutputDir.value, None, logger)
        logger.info("Website built")
      },
      zolaBuildTest := {
        val logger  = streams.value.log
        val baseurl = zolaTestBaseUrl.value
        logger.info("Building web site (test) using zola ...")
        (Compile/resources).value
        buildSite(
          zolaCommand.value,
          zolaRootDir.value,
          zolaOutputDir.value,
          Some(baseurl),
          logger
        )
        logger.info(s"Website built. Check it with base-url $baseurl")
      },
      zolaCheck := {
        val logger = streams.value.log
        logger.info("Checking web site using zola ...")
        checkSite(zolaCommand.value, zolaRootDir.value, logger)
      }
    )

  override def projectSettings: Seq[Setting[_]] =
    zolaSettings

  def buildSite(
      zolaCmd: String,
      inDir: File,
      outDir: File,
      base: Option[String],
      logger: Logger
  ): Unit = {
    val baseUrl = base match {
      case Some(url) =>
        Seq("--base-url", url)
      case None =>
        runYarnInstall("yarn", inDir.getParentFile, logger)
        runElmCompile("elm", inDir.getParentFile, inDir, logger)
        Seq.empty
    }
    Cmd.run(
      Seq(zolaCmd, "build", "-o", outDir.absolutePath.toString) ++ baseUrl,
      inDir,
      logger
    )
  }

  def checkSite(zolaCmd: String, inDir: File, logger: Logger): Unit =
    Cmd.run(Seq(zolaCmd, "check"), inDir, logger)

  def runYarnInstall(yarnCmd: String, inDir: File, logger: Logger): Unit =
    Cmd.run(Seq(yarnCmd, "install"), inDir, logger)

  def runElmCompile(elmCmd: String, inDir: File, zolaRoot: File, logger: Logger): Unit =
    Cmd.run(
      Seq(
        elmCmd,
        "make",
        "--output",
        (zolaRoot / "static" / "js" / "bundle.js").absolutePath.toString,
        "--optimize",
        (inDir / "elm" / "Main.elm").toString
      ),
      inDir,
      logger
    )

}
