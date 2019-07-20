import com.github.eikek.sbt.openapi._
import scala.sys.process._
import com.typesafe.sbt.SbtGit.GitKeys._

val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.0",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding", "UTF-8",
    "-language:higherKinds",
    "-language:postfixOps",
    "-feature",
    "-Xfatal-warnings", // fail when there are warnings
    "-unchecked",
    "-Xlint",
    "-Ywarn-dead-code",
    "-Ywarn-numeric-widen",
    "-Ywarn-value-discard"
  ),
  scalacOptions in (Compile, console) := Seq()
)

val testSettings = Seq(
  testFrameworks += new TestFramework("minitest.runner.Framework"),
  libraryDependencies ++= Dependencies.miniTest
)

val elmSettings = Seq(
  Compile/resourceGenerators += (Def.task {
    compileElm(streams.value.log
      , (Compile/baseDirectory).value
      , (Compile/resourceManaged).value
      , name.value
      , version.value)
  }).taskValue,
  watchSources += Watched.WatchSource(
    (Compile/sourceDirectory).value/"elm"
      , FileFilter.globFilter("*.elm")
      , HiddenFileFilter
  )
)

val webjarSettings = Seq(
  Compile/resourceGenerators += (Def.task {
    copyWebjarResources(Seq((sourceDirectory in Compile).value/"webjar")
      , (Compile/resourceManaged).value
      , name.value
      , version.value
      , streams.value.log
    )
  }).taskValue,
  watchSources += Watched.WatchSource(
    (Compile / sourceDirectory).value/"webjar"
      , FileFilter.globFilter("*.js") || FileFilter.globFilter("*.css")
      , HiddenFileFilter
  )
)

val debianSettings = Seq(
  maintainer := "Eike Kettner <eike.kettner@posteo.de>",
  packageSummary := description.value,
  packageDescription := description.value,
  mappings in Universal += {
    val conf = (Compile / resourceDirectory).value / "reference.conf"
    if (!conf.exists) {
      sys.error(s"File $conf not found")
    }
    conf -> "conf/docspell.conf"
  },
  bashScriptExtraDefines += """addJava "-Dconfig.file=${app_home}/../conf/docspell.conf""""
)

val buildInfoSettings = Seq(
  buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion, gitHeadCommit, gitHeadCommitDate, gitUncommittedChanges, gitDescribedVersion),
  buildInfoOptions += BuildInfoOption.ToJson,
  buildInfoOptions += BuildInfoOption.BuildTime
)



val common = project.in(file("modules/common")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-common",
    libraryDependencies ++=
      Dependencies.fs2
  )

val store = project.in(file("modules/store")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-store",
    libraryDependencies ++=
      Dependencies.doobie ++
      Dependencies.bitpeace ++
      Dependencies.fs2 ++
      Dependencies.databases ++
      Dependencies.flyway ++
      Dependencies.loggingApi
  )

val restapi = project.in(file("modules/restapi")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-restapi",
    libraryDependencies ++=
      Dependencies.circe,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.restapi.model"),
    openapiSpec := (Compile/resourceDirectory).value/"docspell-openapi.yml",
    openapiScalaConfig := ScalaConfig().withJson(ScalaJson.circeSemiauto)
  )

val joexapi = project.in(file("modules/joexapi")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-joexapi",
    libraryDependencies ++=
      Dependencies.circe,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.joexapi.model"),
    openapiSpec := (Compile/resourceDirectory).value/"joex-openapi.yml",
    openapiScalaConfig := ScalaConfig().withJson(ScalaJson.circeSemiauto)
  )

val joex = project.in(file("modules/joex")).
  enablePlugins(BuildInfoPlugin
    , JavaServerAppPackaging
    , DebianPlugin
    , SystemdPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(debianSettings).
  settings(buildInfoSettings).
  settings(
    name := "docspell-joex",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.http4s ++
      Dependencies.circe ++
      Dependencies.pureconfig ++
      Dependencies.loggingApi ++
      Dependencies.logging,
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.joex"
  ).dependsOn(store, joexapi, restapi)

val backend = project.in(file("modules/backend")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-backend",
    libraryDependencies ++=
      Dependencies.loggingApi ++
      Dependencies.fs2
  ).dependsOn(store)

val webapp = project.in(file("modules/webapp")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(elmSettings).
  settings(webjarSettings).
  settings(
    name := "docspell-webapp",
    openapiTargetLanguage := Language.Elm,
    openapiPackage := Pkg("Api.Model"),
    openapiSpec := (restapi/Compile/resourceDirectory).value/"docspell-openapi.yml",
    openapiElmConfig := ElmConfig().withJson(ElmJson.decodePipeline)
  )

val restserver = project.in(file("modules/restserver")).
  enablePlugins(BuildInfoPlugin
    , JavaServerAppPackaging
    , DebianPlugin
    , SystemdPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(debianSettings).
  settings(buildInfoSettings).
  settings(
    name := "docspell-restserver",
    libraryDependencies ++=
      Dependencies.http4s ++
      Dependencies.circe ++
      Dependencies.pureconfig ++
      Dependencies.yamusca ++
      Dependencies.webjars ++
      Dependencies.loggingApi ++
      Dependencies.logging,
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.restserver",
    Compile/sourceGenerators += (Def.task {
      createWebjarSource(Dependencies.webjars, (Compile/sourceManaged).value)
    }).taskValue,
    Compile/unmanagedResourceDirectories ++= Seq((Compile/resourceDirectory).value.getParentFile/"templates")
  ).dependsOn(restapi, joexapi, backend, webapp)

val root = project.in(file(".")).
  settings(sharedSettings).
  settings(
    name := "docspell-root"
  ).
  aggregate(common, store, joexapi, joex, backend, webapp, restapi, restserver)


def copyWebjarResources(src: Seq[File], base: File, artifact: String, version: String, logger: Logger): Seq[File] = {
  val targetDir = base/"META-INF"/"resources"/"webjars"/artifact/version
  src.flatMap { dir =>
    if (dir.isDirectory) {
      val files = (dir ** "*").filter(_.isFile).get pair Path.relativeTo(dir)
      files.map { case (f, name) =>
        val target = targetDir/name
        logger.info(s"Copy $f -> $target")
        IO.createDirectories(Seq(target.getParentFile))
        IO.copy(Seq(f -> target))
        target
      }
    } else {
      val target = targetDir/dir.name
      logger.info(s"Copy $dir -> $target")
      IO.createDirectories(Seq(target.getParentFile))
      IO.copy(Seq(dir -> target))
      Seq(target)
    }
  }
}

def compileElm(logger: Logger, wd: File, outBase: File, artifact: String, version: String): Seq[File] = {
  logger.info("Compile elm files ...")
  val target = outBase/"META-INF"/"resources"/"webjars"/artifact/version/"docspell-app.js"
  val proc = Process(Seq("elm", "make", "--output", target.toString) ++ Seq(wd/"src"/"main"/"elm"/"Main.elm").map(_.toString), Some(wd))
  val out = proc.!!
  logger.info(out)
  Seq(target)
}

def createWebjarSource(wj: Seq[ModuleID], out: File): Seq[File] = {
  val target = out/"Webjars.scala"
  val fields = wj.map(m => s"""val ${m.name.toLowerCase.filter(_ != '-')} = "/${m.name}/${m.revision}" """).mkString("\n\n")
  val content = s"""package docspell.restserver.webapp
    |object Webjars {
    |$fields
    |}
    |""".stripMargin

  IO.write(target, content)
  Seq(target)
}
