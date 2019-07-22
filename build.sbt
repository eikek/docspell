import com.github.eikek.sbt.openapi._
import scala.sys.process._
import com.typesafe.sbt.SbtGit.GitKeys._
import docspell.build._

val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.1",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding", "UTF-8",
    "-language:higherKinds",
    "-language:postfixOps",
    "-feature",
    "-Werror", // fail when there are warnings
    "-unchecked",
    "-Xlint:_",
    "-Ywarn-dead-code",
    "-Ywarn-numeric-widen",
    "-Ywarn-value-discard"
  ),
  scalacOptions in (Compile, console) :=
    (scalacOptions.value.filter(o => !o.contains("Xlint")) ++ Seq("-Xlint:_,-unused")),
  scalacOptions in (Test, console) :=
    (scalacOptions.value.filter(o => !o.contains("Xlint")) ++ Seq("-Xlint:_,-unused"))
)

val testSettings = Seq(
  testFrameworks += new TestFramework("minitest.runner.Framework"),
  libraryDependencies ++= Dependencies.miniTest ++ Dependencies.logging.map(_ % Test)
)

val elmSettings = Seq(
  Compile/resourceGenerators += Def.task {
    compileElm(streams.value.log
      , (Compile/baseDirectory).value
      , (Compile/resourceManaged).value
      , name.value
      , version.value)
  }.taskValue,
  watchSources += Watched.WatchSource(
    (Compile/sourceDirectory).value/"elm"
      , FileFilter.globFilter("*.elm")
      , HiddenFileFilter
  )
)

val webjarSettings = Seq(
  Compile/resourceGenerators += Def.task {
    copyWebjarResources(Seq((sourceDirectory in Compile).value/"webjar")
      , (Compile/resourceManaged).value
      , name.value
      , version.value
      , streams.value.log
    )
  }.taskValue,
  watchSources += Watched.WatchSource(
    (Compile / sourceDirectory).value/"webjar"
      , FileFilter.globFilter("*.js") || FileFilter.globFilter("*.css")
      , HiddenFileFilter
  )
)

def debianSettings(cfgFile: String) = Seq(
  maintainer := "Eike Kettner <eike.kettner@posteo.de>",
  packageSummary := description.value,
  packageDescription := description.value,
  mappings in Universal += {
    val conf = (Compile / resourceDirectory).value / "reference.conf"
    if (!conf.exists) {
      sys.error(s"File $conf not found")
    }
    conf -> s"conf/$cfgFile.conf"
  },
  bashScriptExtraDefines += s"""addJava "-Dconfig.file=$${app_home}/../conf/$cfgFile.conf""""
)

val buildInfoSettings = Seq(
  buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion, gitHeadCommit, gitHeadCommitDate, gitUncommittedChanges, gitDescribedVersion),
  buildInfoOptions += BuildInfoOption.ToJson,
  buildInfoOptions += BuildInfoOption.BuildTime
)

val openapiScalaSettings = Seq(
  openapiScalaConfig := ScalaConfig().withJson(ScalaJson.circeSemiauto).
    addMapping(CustomMapping.forType({
      case TypeDef("LocalDateTime", _)  =>
        TypeDef("Timestamp", Imports("docspell.common.Timestamp"))
    })).
    addMapping(CustomMapping.forFormatType({
      case "ident" => field =>
        field.copy(typeDef = TypeDef("Ident", Imports("docspell.common.Ident")))
      case "collectivestate" => field =>
        field.copy(typeDef = TypeDef("CollectiveState", Imports("docspell.common.CollectiveState")))
      case "userstate" => field =>
        field.copy(typeDef = TypeDef("UserState", Imports("docspell.common.UserState")))
      case "password" => field =>
        field.copy(typeDef = TypeDef("Password", Imports("docspell.common.Password")))
      case "contactkind" => field =>
        field.copy(typeDef = TypeDef("ContactKind", Imports("docspell.common.ContactKind")))
      case "direction" => field =>
        field.copy(typeDef = TypeDef("Direction", Imports("docspell.common.Direction")))
      case "priority" => field =>
        field.copy(typeDef = TypeDef("Priority", Imports("docspell.common.Priority")))
      case "jobstate" => field =>
        field.copy(typeDef = TypeDef("JobState", Imports("docspell.common.JobState")))
      case "loglevel" => field =>
        field.copy(typeDef = TypeDef("LogLevel", Imports("docspell.common.LogLevel")))
      case "mimetype" => field =>
        field.copy(typeDef = TypeDef("MimeType", Imports("docspell.common.MimeType")))
      case "itemstate" => field =>
        field.copy(typeDef = TypeDef("ItemState", Imports("docspell.common.ItemState")))
      case "nertag" => field =>
        field.copy(typeDef = TypeDef("NerTag", Imports("docspell.common.NerTag")))
      case "language" => field =>
        field.copy(typeDef = TypeDef("Language", Imports("docspell.common.Language")))
    }))
)

val reStartSettings = Seq(
  javaOptions in reStart ++= Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"dev.conf"}")
)

// --- Modules

val common = project.in(file("modules/common")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-common",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.circe ++
      Dependencies.loggingApi ++
      Dependencies.pureconfig.map(_ % "optional")
  )

val store = project.in(file("modules/store")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-store",
    libraryDependencies ++=
      Dependencies.doobie ++
      Dependencies.bitpeace ++
      Dependencies.tika ++
      Dependencies.fs2 ++
      Dependencies.databases ++
      Dependencies.flyway ++
      Dependencies.loggingApi
  ).dependsOn(common)

val text = project.in(file("modules/text")).
  enablePlugins(NerModelsPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(NerModelsPlugin.nerClassifierSettings).
  settings(
    name := "docspell-text",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.tika ++
      Dependencies.stanfordNlpCore
  ).dependsOn(common)
  
val restapi = project.in(file("modules/restapi")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(openapiScalaSettings).
  settings(
    name := "docspell-restapi",
    libraryDependencies ++=
      Dependencies.circe,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.restapi.model"),
    openapiSpec := (Compile/resourceDirectory).value/"docspell-openapi.yml",
  ).dependsOn(common)

val joexapi = project.in(file("modules/joexapi")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(openapiScalaSettings).
  settings(
    name := "docspell-joexapi",
    libraryDependencies ++=
      Dependencies.circe,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.joexapi.model"),
    openapiSpec := (Compile/resourceDirectory).value/"joex-openapi.yml"
  ).dependsOn(common)

val joex = project.in(file("modules/joex")).
  enablePlugins(BuildInfoPlugin
    , JavaServerAppPackaging
    , DebianPlugin
    , SystemdPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(debianSettings("docspell-joex")).
  settings(buildInfoSettings).
  settings(
    name := "docspell-joex",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.http4s ++
      Dependencies.circe ++
      Dependencies.pureconfig ++
      Dependencies.loggingApi ++
      Dependencies.logging.map(_ % Runtime),
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.joex",
    reStart/javaOptions ++= Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"dev.conf"}")
  ).dependsOn(store, text, joexapi, restapi)

val backend = project.in(file("modules/backend")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-backend",
    libraryDependencies ++=
      Dependencies.loggingApi ++
      Dependencies.fs2 ++
      Dependencies.bcrypt ++
      Dependencies.http4sClient
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
  settings(debianSettings("docspell-server")).
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
      Dependencies.logging.map(_ % Runtime),
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.restserver",
    Compile/sourceGenerators += Def.task {
      createWebjarSource(Dependencies.webjars, (Compile/sourceManaged).value)
    }.taskValue,
    Compile/resourceGenerators += Def.task {
      copyWebjarResources(Seq((restapi/Compile/resourceDirectory).value/"docspell-openapi.yml")
        , (Compile/resourceManaged).value
        , name.value
        , version.value
        , streams.value.log)
    }.taskValue,
    Compile/unmanagedResourceDirectories ++= Seq((Compile/resourceDirectory).value.getParentFile/"templates"),
    reStart/javaOptions ++= Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"dev.conf"}")
  ).dependsOn(restapi, joexapi, backend, webapp)

val microsite = project.in(file("modules/microsite")).
  enablePlugins(MicrositesPlugin).
  settings(sharedSettings).
  settings(
    name := "docspell-microsite",
    publishArtifact := false,
    scalacOptions -= "-Yno-imports",
    scalacOptions ~= { _ filterNot (_ startsWith "-Ywarn") },
    scalacOptions ~= { _ filterNot (_ startsWith "-Xlint") },
    scalaVersion := "2.12.9",
    skip in publish := true,
    micrositeFooterText := Some(
      """
        |<p>&copy; 2019 <a href="https://github.com/eikek/docspell">Docspell, v{{site.version}}</a></p>
        |""".stripMargin
    ),
    micrositeName := "Docspell",
    micrositeDescription := "Docspell – A Document Organizer",
    micrositeBaseUrl := "/docspell",
    micrositeAuthor := "eikek",
    micrositeGithubOwner := "eikek",
    micrositeGithubRepo := "docspell",
    micrositeGitterChannel := false,
    micrositeFavicons := Seq(microsites.MicrositeFavicon("favicon.png", "96x96")),
    micrositeShareOnSocial := false,
    micrositeHighlightLanguages ++= Seq("json", "javascript"),
    micrositePalette := Map(
      "brand-primary"     -> "#5d000a", // link color
      "brand-secondary"   -> "#172651", //sidebar background
      "brand-tertiary"    -> "#495680", //main brand background
      "gray-dark"         -> "#050913", //header font color
      "gray"              -> "#131f43", //font color
      "gray-light"        -> "#E3E2E3",
      "gray-lighter"      -> "#f8fbff", //body background
      "white-color"       -> "#FFFFFF"),
    fork in tut := true,
    scalacOptions in Tut ~= (_.filterNot(Set("-Ywarn-unused-import", "-Ywarn-dead-code", "-Werror"))),
    resourceGenerators in Tut += Def.task {
      val conf1 = (resourceDirectory in (restserver, Compile)).value / "reference.conf"
      val conf2 = (resourceDirectory in (joex, Compile)).value / "reference.conf"      
      val out1 = resourceManaged.value/"main"/"jekyll"/"_includes"/"server.conf"
      val out2 = resourceManaged.value/"main"/"jekyll"/"_includes"/"joex.conf"
      streams.value.log.info(s"Copying reference.conf: $conf1 -> $out1, $conf2 -> $out2")
      IO.write(out1, "{% raw %}\n")
      IO.append(out1, IO.readBytes(conf1))
      IO.write(out1, "\n{% endraw %}", append = true)
      IO.write(out2, "{% raw %}\n")
      IO.append(out2, IO.readBytes(conf2))
      IO.write(out2, "\n{% endraw %}", append = true)
      val oa1 = (resourceDirectory in (restapi, Compile)).value/"docspell-openapi.yml"
      val oaout = resourceManaged.value/"main"/"jekyll"/"openapi"/"docspell-openapi.yml"
      IO.copy(Seq(oa1 -> oaout))
      Seq(out1, out2, oaout)
    }.taskValue,
    resourceGenerators in Tut += Def.task {
      val staticDoc = (restapi/Compile/openapiStaticDoc).value
      val target = resourceManaged.value/"main"/"jekyll"/"openapi"/"docspell-openapi.html"
      IO.copy(Seq(staticDoc -> target))
      Seq(target)
    }.taskValue,
    micrositeCompilingDocsTool := WithTut //WithMdoc
//    mdocIn                     := sourceDirectory.value / "main" / "tut"
  )

val root = project.in(file(".")).
  settings(sharedSettings).
  settings(
    name := "docspell-root"
  ).
  aggregate(common
    , text
    , store
    , joexapi
    , joex
    , backend
    , webapp
    , restapi
    , restserver
    , microsite)



// --- helpers

def copyWebjarResources(src: Seq[File], base: File, artifact: String, version: String, logger: Logger): Seq[File] = {
  val targetDir = base/"META-INF"/"resources"/"webjars"/artifact/version
  logger.info(s"Copy webjar resources from ${src.size} files/directories.")
  src.flatMap { dir =>
    if (dir.isDirectory) {
      val files = (dir ** "*").filter(_.isFile).get pair Path.relativeTo(dir)
      files.map { case (f, name) =>
        val target = targetDir/name
        IO.createDirectories(Seq(target.getParentFile))
        IO.copy(Seq(f -> target))
        target
      }
    } else {
      val target = targetDir/dir.name
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


addCommandAlias("make", ";root/openapiCodegen ;root/test:compile")
addCommandAlias("make-zip", ";restserver/universal:packageBin ;joex/universal:packageBin")
addCommandAlias("make-deb", ";restserver/debian:packageBin ;joex/debian:packageBin")
addCommandAlias("make-pkg", ";make-zip ;make-deb")
