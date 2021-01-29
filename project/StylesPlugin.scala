package docspell.build

import sbt._
import sbt.Keys._
import scala.sys.process._

/** Integrates the tailwind build into sbt.
  *
  * It assumes the required config (postcss.conf.js,
  * tailwind.config.js) files in the base directory. It requires to
  * have nodejs installed and the npx command available (or
  * configured).
  */
object StylesPlugin extends AutoPlugin {

  object autoImport {

    sealed trait StylesMode
    object StylesMode {
      case object Prod extends StylesMode
      case object Dev  extends StylesMode
    }

    val stylesDirectory  = settingKey[File]("The directory containing source styles")
    val stylesOutputDir  = settingKey[File]("The directory to put the final outcome")
    val stylesMode       = settingKey[StylesMode]("The compile mode, dev or production")
    val stylesNpxCommand = settingKey[String]("The npx executable")
    val stylesNpmCommand =
      settingKey[String]("The npm executable for installing dependencies")

    val stylesBuild = taskKey[Seq[File]](
      "Build the css without minifying and purging."
    )
    val stylesInstall = taskKey[Unit]("Run npm install to install dependencies")
  }

  import autoImport._

  def stylesSettings: Seq[Setting[_]] =
    Seq(
      stylesDirectory := (Compile / sourceDirectory).value / "styles",
      stylesOutputDir := (Compile / resourceManaged).value /
        "META-INF" / "resources" / "webjars" / name.value / version.value,
      stylesNpxCommand := "npx",
      stylesNpmCommand := "npm",
      stylesMode := StylesMode.Dev,
      stylesBuild := {
        val logger = streams.value.log
        val npx    = stylesNpxCommand.value
        val npm    = stylesNpmCommand.value
        val inDir  = stylesDirectory.value
        val outDir = stylesOutputDir.value
        val wd     = (LocalRootProject / baseDirectory).value
        val mode   = stylesMode.value
        npmInstall(npm, wd, logger)
        val files = postCss(npx, inDir, outDir, wd, mode, logger) ++
          copyWebfonts(wd, outDir, logger)
        logger.info("Styles built")
        files
      },
      stylesInstall := {
        val logger = streams.value.log
        val npm    = stylesNpmCommand.value
        val wd     = (LocalRootProject / baseDirectory).value
        npmInstall(npm, wd, logger)
      }
    )

  override def projectSettings: Seq[Setting[_]] =
    stylesSettings

  def npmInstall(npm: String, wd: File, logger: Logger): Unit = {
    val modulesDir = wd / "node_modules"
    if (!modulesDir.exists) {
      logger.info("Running npm install …")
      Cmd.run(Seq(npm, "install"), wd, logger)
    }
  }

  def postCss(
      npx: String,
      inDir: File,
      outDir: File,
      wd: File,
      mode: StylesMode,
      logger: Logger
  ): Seq[File] = {
    val env = mode match {
      case StylesMode.Dev  => "development"
      case StylesMode.Prod => "production"
    }
    val target = outDir / "css" / "styles.css"
    IO.createDirectory(target.getParentFile)
    logger.info("Compiling css stylesheets…")
    Cmd.run(
      Seq(
        npx,
        "postcss",
        s"${inDir}/*.css",
        "-o",
        target.absolutePath,
        "--env",
        env
      ),
      wd,
      logger
    )
    val gz = file(target.toString + ".gz")
    IO.gzip(target, gz)
    Seq(target, gz)
  }

  def copyWebfonts(baseDir: File, outDir: File, logger: Logger): Seq[File] = {
    val fontDir =
      baseDir / "node_modules" / "@fortawesome" / "fontawesome-free" / "webfonts"
    val targetDir = outDir / "webfonts"
    IO.createDirectory(targetDir)
    IO.copy(fontDir.listFiles().map(f => f -> targetDir / f.name).toSeq)
    IO.listFiles(targetDir).toSeq
  }
}
