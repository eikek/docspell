import com.github.eikek.sbt.openapi._
import scala.sys.process._
import com.typesafe.sbt.SbtGit.GitKeys._
import docspell.build._
import microsites.ExtraMdFileConfig

val toolsPackage = taskKey[Seq[File]]("Package the scripts/extension tools")
val elmCompileMode = settingKey[ElmCompileMode]("How to compile elm sources")

val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.2",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding", "UTF-8",
    "-language:higherKinds",
    "-feature",
    "-Werror", // fail when there are warnings
    "-unchecked",
    "-Xlint:_",
    "-Wdead-code",
    "-Wunused",
    "-Wvalue-discard",
    "-Wnumeric-widen"
  ),
  LocalRootProject/toolsPackage := {
    val v = version.value
    val logger = streams.value.log
    val dir = (LocalRootProject/baseDirectory).value / "tools"
    packageTools(logger, dir, v)
  },
  scalacOptions in (Compile, console) :=
    (scalacOptions.value.filter(o => !o.contains("Xlint")) ++ Seq("-Xlint:_,-unused")),
  scalacOptions in (Test, console) :=
    (scalacOptions.value.filter(o => !o.contains("Xlint")) ++ Seq("-Xlint:_,-unused"))
)

val testSettings = Seq(
  testFrameworks += new TestFramework("minitest.runner.Framework"),
  libraryDependencies ++= Dependencies.miniTest ++ Dependencies.logging.map(_ % Test)
)

lazy val noPublish = Seq(
  publish := {},
  publishLocal := {},
  publishArtifact := false
)


val elmSettings = Seq(
  elmCompileMode := ElmCompileMode.Debug,
  Compile/resourceGenerators += Def.task {
    compileElm(streams.value.log
      , (Compile/baseDirectory).value
      , (Compile/resourceManaged).value
      , name.value
      , version.value
      , elmCompileMode.value)
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
      case "calevent" => field =>
        field.copy(typeDef = TypeDef("CalEvent", Imports("com.github.eikek.calev.CalEvent",
          "com.github.eikek.calev.circe.CalevCirceCodec._")))
    }))
)

// --- Modules

// Base module, everything depends on this – including restapi and
// joexapi modules. This should aim to have least possible
// dependencies
val common = project.in(file("modules/common")).
  disablePlugins(RevolverPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-common",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.circe ++
      Dependencies.loggingApi ++
      Dependencies.calevCore ++
      Dependencies.calevCirce ++
      Dependencies.pureconfig.map(_ % "optional")
  )

// Some example files for testing
// https://file-examples.com/index.php/sample-documents-download/sample-doc-download/
val files = project.in(file("modules/files")).
  disablePlugins(RevolverPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-files",
    libraryDependencies ++=
      Dependencies.tika ++
      Dependencies.icu4j,
    Test / sourceGenerators += Def.task {
      val base = (Test/resourceDirectory).value
      val files = (base ** (_.isFile)) pair sbt.io.Path.relativeTo(base)
      val lines = files.toList.map(_._2).map(s => {
        val ident = s.replaceAll("[^a-zA-Z0-9_]+", "_")
        ident -> s"""val $ident = createUrl("${s}")"""
      })
      val content = s"""package docspell.files

object ExampleFiles extends ExampleFilesSupport {

${lines.map(_._2).mkString("\n")}

val all = List(
${lines.map(_._1).mkString(",\n")}
)

}
"""
      val target = (Test/sourceManaged).value/"scala"/"ExampleFiles.scala"
      IO.createDirectory(target.getParentFile)
      IO.write(target, content)
      Seq(target)
    }.taskValue
  ).dependsOn(common)

val store = project.in(file("modules/store")).
  disablePlugins(RevolverPlugin).
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
      Dependencies.loggingApi ++
      Dependencies.emil ++
      Dependencies.emilDoobie ++
      Dependencies.calevCore ++
      Dependencies.calevFs2
  ).dependsOn(common)

val extract = project.in(file("modules/extract")).
  disablePlugins(RevolverPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-extract",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.twelvemonkeys ++      
      Dependencies.pdfbox ++
      Dependencies.poi ++
      Dependencies.commonsIO ++
      Dependencies.julOverSlf4j
  ).dependsOn(common, files % "compile->compile;test->test")

val convert = project.in(file("modules/convert")).
  disablePlugins(RevolverPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-convert",
    libraryDependencies ++=
      Dependencies.flexmark ++
      Dependencies.twelvemonkeys
  ).dependsOn(common, files % "compile->compile;test->test")

val analysis = project.in(file("modules/analysis")).
  disablePlugins(RevolverPlugin).
  enablePlugins(NerModelsPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(NerModelsPlugin.nerClassifierSettings).
  settings(
    name := "docspell-analysis",
    libraryDependencies ++=
      Dependencies.fs2 ++
      Dependencies.stanfordNlpCore
  ).dependsOn(common, files % "test->test")
  
val restapi = project.in(file("modules/restapi")).
  disablePlugins(RevolverPlugin).
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
  disablePlugins(RevolverPlugin).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(openapiScalaSettings).
  settings(
    name := "docspell-joexapi",
    libraryDependencies ++=
      Dependencies.circe ++
      Dependencies.http4sClient,
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
      Dependencies.emilTnef ++
      Dependencies.emilMarkdown ++
      Dependencies.emilJsoup ++
      Dependencies.jsoup ++
      Dependencies.yamusca ++
      Dependencies.loggingApi ++
      Dependencies.logging.map(_ % Runtime),
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.joex",
    reStart/javaOptions ++= Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"local"/"dev.conf"}")
  ).dependsOn(store, extract, convert, analysis, joexapi, restapi)

val backend = project.in(file("modules/backend")).
  disablePlugins(RevolverPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-backend",
    libraryDependencies ++=
      Dependencies.loggingApi ++
      Dependencies.fs2 ++
      Dependencies.bcrypt ++
      Dependencies.http4sClient ++
      Dependencies.emil
  ).dependsOn(store, joexapi)

val webapp = project.in(file("modules/webapp")).
  disablePlugins(RevolverPlugin).
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
    reStart/javaOptions ++= Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"local"/"dev.conf"}")
  ).dependsOn(restapi, joexapi, backend, webapp)

val microsite = project.in(file("modules/microsite")).
  disablePlugins(RevolverPlugin).
  enablePlugins(MicrositesPlugin).
  disablePlugins(ReleasePlugin).
  settings(sharedSettings).
  settings(
    name := "docspell-microsite",
    publishArtifact := false,
    skip in publish := true,
    micrositeFooterText := Some(
      """
        |<p>&copy; 2020 <a href="https://github.com/eikek/docspell">Docspell, v{{site.version}}</a></p>
        |""".stripMargin
    ),
    micrositeName := "Docspell",
    micrositeDescription := "Auto-tagging Document Organizer",
    micrositeDocumentationUrl := "doc",
    micrositeDocumentationLabelDescription := "Documentation",
    micrositeFavicons := Seq(microsites.MicrositeFavicon("favicon.png", "96x96")),
    micrositeAuthor := "eikek",
    micrositeGithubOwner := "eikek",
    micrositeGithubRepo := "docspell",
    micrositeGitterChannel := false,
    micrositeShareOnSocial := false,
    micrositeHighlightLanguages ++= Seq("json", "javascript"),
    micrositeEditButton := Some(microsites.MicrositeEditButton("Improve this page", "/edit/master/modules/microsite/docs/{{ page.path }}")),
    fork in run := true,
    micrositeCompilingDocsTool := WithMdoc,
    mdocVariables := Map(
      "VERSION" -> version.value,
      "PVERSION" -> version.value.replace('.', '_')
    ),
    micrositeExtraMdFiles := Map(
      file("Changelog.md") -> ExtraMdFileConfig(
        "changelog.md",
        "docs",
        Map("title" -> "Changelog", "permalink" -> "changelog")
      )
    ),
    Compile/resourceGenerators += Def.task {
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
    Compile/resourceGenerators += Def.task {
      val staticDoc = (restapi/Compile/openapiStaticDoc).value
      val target = resourceManaged.value/"main"/"jekyll"/"openapi"/"docspell-openapi.html"
      IO.copy(Seq(staticDoc -> target))
      Seq(target)
    }.taskValue
  )

val root = project.in(file(".")).
  settings(sharedSettings).
  settings(noPublish).
  settings(
    name := "docspell-root"
  ).
  aggregate(common
    , extract
    , convert
    , analysis
    , files
    , store
    , joexapi
    , joex
    , backend
    , webapp
    , restapi
    , restserver)



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

def compileElm(logger: Logger, wd: File, outBase: File, artifact: String, version: String, mode: ElmCompileMode): Seq[File] = {
  logger.info("Compile elm files ...")
  val target = outBase/"META-INF"/"resources"/"webjars"/artifact/version/"docspell-app.js"
  val cmd = Seq("elm", "make") ++ mode.flags ++ Seq("--output", target.toString)
  val proc = Process(cmd ++ Seq(wd/"src"/"main"/"elm"/"Main.elm").map(_.toString), Some(wd))
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

def packageTools(logger: Logger, dir: File, version: String): Seq[File] = {
  val target = dir/"target"
  IO.delete(target)
  IO.createDirectory(target)
  val archive = target/s"docspell-tools-${version}.zip"
  logger.info(s"Packaging tools to $archive ...")
  val webext = target/"docspell-firefox-extension.xpi"
  val wx = dir/"webextension"
  IO.zip(Seq(
    wx/"_locales/de/messages.json" -> "_locales/de/messages.json",
    wx/"_locales/en/messages.json" -> "_locales/en/messages.json",
    wx/"docspell.js" -> "docspell.js",
    wx/"icons"/"logo-48.png" -> "icons/logo-48.png",
    wx/"icons"/"logo-96.png" -> "icons/logo-96.png",
    wx/"manifest.json" -> "manifest.json"
  ), webext)

  IO.zip(Seq(
    webext -> s"docspell-tools-${version}/firefox/docspell-extension.xpi",
    wx/"native/app_manifest.json" ->s"docspell-tools-${version}/firefox/native/app_manifest.json",
    wx/"native/native.py" ->s"docspell-tools-${version}/firefox/native/native.py",
    dir/"ds.sh" -> s"docspell-tools-${version}/ds.sh",
    dir/"consumedir.sh" -> s"docspell-tools-${version}/consumedir.sh"
  ), archive)

  Seq(archive)
}

// --- aliases

addCommandAlias("make", ";set webapp/elmCompileMode := ElmCompileMode.Production ;root/openapiCodegen ;root/test:compile")
addCommandAlias("make-zip", ";restserver/universal:packageBin ;joex/universal:packageBin")
addCommandAlias("make-deb", ";restserver/debian:packageBin ;joex/debian:packageBin")
addCommandAlias("make-tools", ";root/toolsPackage")
addCommandAlias("make-pkg", ";clean ;make ;make-zip ;make-deb ;make-tools")
