package docspell.build

import sbt._
import sbt.Keys._
import sbt.nio.file.FileTreeView
import scala.sys.process._

object ZolaPlugin extends AutoPlugin {

  object autoImport {
    val zolaRootDir = settingKey[File]("The root directory of zola")
    val zolaOutputDir = settingKey[File]("The directory to put the final site")
    val zolaCommand = settingKey[String]("The zola executable")
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
    val zolaPrepare = taskKey[Unit]("Some task to run before generating docs")
  }

  import autoImport._

  def zolaSettings: Seq[Setting[_]] =
    Seq(
      zolaRootDir := baseDirectory.value / "site",
      zolaOutputDir := target.value / "zola-site",
      zolaCommand := "zola",
      zolaTestBaseUrl := "http://localhost:1234",
      zolaPrepare := {},
      zolaBuild := {
        val logger = streams.value.log
        logger.info("Building web site using zola ...")
        (Compile / resources).value
        zolaPrepare.value
        buildSite(zolaCommand.value, zolaRootDir.value, zolaOutputDir.value, None, logger)
        logger.info("Website built")
      },
      zolaBuildTest := {
        val logger = streams.value.log
        val baseurl = zolaTestBaseUrl.value
        logger.info("Building web site (test) using zola ...")
        (Compile / resources).value
        zolaPrepare.value
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
        Seq.empty
    }
    runYarnInstall("yarn", inDir.getParentFile, logger)
    runElmCompile("elm", inDir.getParentFile, inDir, logger)
    runTailwind("npx", inDir.getParentFile, inDir, logger)

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
        (inDir / "elm" / "Main.elm").toString,
        (inDir / "elm" / "Search.elm").toString
      ),
      inDir,
      logger
    )

  def runTailwind(npx: String, inDir: File, zolaRoot: File, logger: Logger): Unit = {
    val fontTarget = zolaRoot / "static" / "files"
    val iconTarget = zolaRoot / "static" / "webfonts"
    IO.createDirectories(Seq(fontTarget, iconTarget))

    val fontIn = Glob(inDir / "node_modules" / "@fontsource") / * / "files" / *
    val fontInFiles = FileTreeView.default.list(fontIn).map(_._1.toFile())
    logger.info(s"Copy ${fontInFiles.size} webfonts from node_modules to ${fontTarget}…")
    IO.copy(fontInFiles.pair(Path.flat(fontTarget)))

    val iconIn =
      Glob(inDir / "node_modules" / "@fortawesome" / "fontawesome-free" / "webfonts") / *
    val iconInFiles = FileTreeView.default.list(iconIn).map(_._1.toFile())
    logger.info(s"Copy ${iconInFiles.size} icons from node_modules to ${iconTarget}…")
    IO.copy(iconInFiles.pair(Path.flat(iconTarget)))

    logger.info("Running tailwind…")
    Cmd.run(
      Seq(
        npx,
        "tailwindcss",
        "-i",
        (inDir / "styles" / "input.css").toString,
        "-o",
        (zolaRoot / "static" / "styles.css").toString,
        "--config",
        (inDir / "tailwind.config.js").toString,
        "--postcss",
        (inDir / "postcss.config.js").toString,
        "--minify"
      ),
      inDir,
      logger
    )
  }
}
