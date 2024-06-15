import com.github.eikek.sbt.openapi._
import com.github.sbt.git.SbtGit.GitKeys._
import docspell.build._
import de.heikoseeberger.sbtheader.CommentBlockCreator

val toolsPackage = taskKey[Seq[File]]("Package the scripts/extension tools")
val elmCompileMode = settingKey[ElmCompileMode]("How to compile elm sources")

// --- Settings

val scalafixSettings = Seq(
  semanticdbEnabled := true, // enable SemanticDB
  semanticdbVersion := scalafixSemanticdb.revision // "4.4.0"
)

val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.14",
  organizationName := "Eike K. & Contributors",
  licenses += (
    "AGPL-3.0-or-later",
    url(
      "https://spdx.org/licenses/AGPL-3.0-or-later.html"
    )
  ),
  startYear := Some(2020),
  headerLicenseStyle := HeaderLicenseStyle.SpdxSyntax,
  headerSources / excludeFilter := HiddenFileFilter || "*.java" || "StringUtil.scala",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding",
    "UTF-8",
    "-language:higherKinds",
    "-feature",
    "-Werror", // fail when there are warnings
    "-unchecked",
    // remove -byname-implicit, once https://github.com/scala/bug/issues/12072 is resolved
    "-Xlint:-byname-implicit,_",
    "-Wdead-code",
    "-Wunused",
    "-Wvalue-discard",
    "-Wnumeric-widen",
    "-Ywarn-macros:after"
  ),
  javacOptions ++= Seq("-target", "1.8", "-source", "1.8"),
  LocalRootProject / toolsPackage := {
    val v = version.value
    val logger = streams.value.log
    val dir = (LocalRootProject / baseDirectory).value / "tools"
    packageTools(logger, dir, v)
  },
  Compile / console / scalacOptions :=
    (scalacOptions.value.filter(o => !o.contains("-Xlint") && !o.contains("-W"))),
  Test / console / scalacOptions :=
    (scalacOptions.value.filter(o => !o.contains("-Xlint") && !o.contains("-W"))),
  libraryDependencySchemes ++= Seq(
    "com.github.eikek" %% "calev-core" % VersionScheme.Always,
    "com.github.eikek" %% "calev-circe" % VersionScheme.Always
  ),
  addCompilerPlugin(Dependencies.kindProjectorPlugin)
) ++ scalafixSettings

lazy val noPublish = Seq(
  publish := {},
  publishLocal := {},
  publishArtifact := false
)

val elmSettings = Seq(
  elmCompileMode := ElmCompileMode.Debug,
  Compile / resourceGenerators += Def.task {
    val _ = openapiCodegen.value
    compileElm(
      streams.value.log,
      (Compile / baseDirectory).value,
      (Compile / resourceManaged).value,
      name.value,
      version.value,
      elmCompileMode.value
    )
  }.taskValue,
  watchSources += Watched.WatchSource(
    (Compile / sourceDirectory).value / "elm",
    FileFilter.globFilter("*.elm"),
    HiddenFileFilter
  ),
  Compile / unmanagedSourceDirectories += (Compile / sourceDirectory).value / "elm",
  headerSources / includeFilter := "*.elm",
  headerMappings := headerMappings.value + (HeaderFileType("elm") -> HeaderCommentStyle(
    new CommentBlockCreator("{-", "  ", "-}\n"),
    HeaderPattern.commentBetween("\\{\\-", "  ", "\\-\\}")
  ))
)
val stylesSettings = Seq(
  stylesMode := StylesMode.Dev,
  Compile / resourceGenerators += stylesBuild.taskValue
)

def webjarSettings(queryJS: Project) = Seq(
  Compile / resourceGenerators += Def.task {
    copyWebjarResources(
      Seq((Compile / sourceDirectory).value / "webjar"),
      (Compile / resourceManaged).value,
      name.value,
      version.value,
      streams.value.log
    )
  }.taskValue,
  Compile / resourceGenerators += Def.task {
    val logger = streams.value.log
    val out = (queryJS / Compile / fullOptJS).value
    logger.info(s"Produced query js file: ${out.data}")
    copyWebjarResources(
      Seq(out.data),
      (Compile / resourceManaged).value,
      name.value,
      version.value,
      logger
    )
  }.taskValue,
  watchSources += Watched.WatchSource(
    (Compile / sourceDirectory).value / "webjar",
    FileFilter.globFilter("*.js") || FileFilter.globFilter("*.css"),
    HiddenFileFilter
  )
)

def debianSettings(cfgFile: String) =
  Seq(
    maintainer := "Eike Kettner <eikek@posteo.de>",
    Universal / mappings += {
      val conf = (Compile / resourceDirectory).value / "reference.conf"
      if (!conf.exists)
        sys.error(s"File $conf not found")
      conf -> s"conf/$cfgFile.conf"
    },
    daemonUser := "docspell",
    bashScriptExtraDefines += s"""addJava "-Dconfig.file=$${app_home}/../conf/$cfgFile.conf""""
  )

val buildInfoSettings = Seq(
  buildInfoKeys := Seq[BuildInfoKey](
    name,
    version,
    scalaVersion,
    sbtVersion,
    gitHeadCommit,
    gitHeadCommitDate,
    gitUncommittedChanges,
    gitDescribedVersion
  ),
  buildInfoOptions += BuildInfoOption.ToJson,
  buildInfoOptions += BuildInfoOption.BuildTime
)

val openapiScalaSettings = Seq(
  openapiScalaConfig := ScalaConfig()
    .withJson(ScalaJson.circeSemiauto)
    .addMapping(CustomMapping.forType { case TypeDef("LocalDateTime", _) =>
      TypeDef("Timestamp", Imports("docspell.common.Timestamp"))
    })
    .addMapping(CustomMapping.forFormatType {
      case "ident" =>
        field => field.copy(typeDef = TypeDef("Ident", Imports("docspell.common.Ident")))
      case "accountid" =>
        field =>
          field.copy(typeDef = TypeDef("AccountId", Imports("docspell.common.AccountId")))
      case "collectivestate" =>
        field =>
          field.copy(typeDef =
            TypeDef("CollectiveState", Imports("docspell.common.CollectiveState"))
          )
      case "userstate" =>
        field =>
          field.copy(typeDef = TypeDef("UserState", Imports("docspell.common.UserState")))
      case "password" =>
        field =>
          field.copy(typeDef = TypeDef("Password", Imports("docspell.common.Password")))
      case "contactkind" =>
        field =>
          field.copy(typeDef =
            TypeDef("ContactKind", Imports("docspell.common.ContactKind"))
          )
      case "direction" =>
        field =>
          field.copy(typeDef = TypeDef("Direction", Imports("docspell.common.Direction")))
      case "priority" =>
        field =>
          field.copy(typeDef = TypeDef("Priority", Imports("docspell.common.Priority")))
      case "jobstate" =>
        field =>
          field.copy(typeDef = TypeDef("JobState", Imports("docspell.common.JobState")))
      case "loglevel" =>
        field =>
          field.copy(typeDef = TypeDef("LogLevel", Imports("docspell.common.LogLevel")))
      case "mimetype" =>
        field =>
          field.copy(typeDef = TypeDef("MimeType", Imports("docspell.common.MimeType")))
      case "itemstate" =>
        field =>
          field.copy(typeDef = TypeDef("ItemState", Imports("docspell.common.ItemState")))
      case "nertag" =>
        field =>
          field.copy(typeDef = TypeDef("NerTag", Imports("docspell.common.NerTag")))
      case "language" =>
        field =>
          field.copy(typeDef = TypeDef("Language", Imports("docspell.common.Language")))
      case "calevent" =>
        field =>
          field.copy(typeDef =
            TypeDef(
              "CalEvent",
              Imports(
                "com.github.eikek.calev.CalEvent",
                "com.github.eikek.calev.circe.CalevCirceCodec._"
              )
            )
          )
      case "glob" =>
        field => field.copy(typeDef = TypeDef("Glob", Imports("docspell.common.Glob")))
      case "customfieldtype" =>
        field =>
          field.copy(typeDef =
            TypeDef("CustomFieldType", Imports("docspell.common.CustomFieldType"))
          )
      case "listtype" =>
        field =>
          field.copy(typeDef = TypeDef("ListType", Imports("docspell.common.ListType")))
      case "personuse" =>
        field =>
          field.copy(typeDef = TypeDef("PersonUse", Imports("docspell.common.PersonUse")))
      case "orguse" =>
        field =>
          field.copy(typeDef = TypeDef("OrgUse", Imports("docspell.common.OrgUse")))
      case "equipmentuse" =>
        field =>
          field.copy(typeDef =
            TypeDef("EquipmentUse", Imports("docspell.common.EquipmentUse"))
          )
      case "searchmode" =>
        field =>
          field
            .copy(typeDef = TypeDef("SearchMode", Imports("docspell.common.SearchMode")))
      case "duration" =>
        field =>
          field
            .copy(typeDef = TypeDef("Duration", Imports("docspell.common.Duration")))
      case "uri" =>
        field =>
          field
            .copy(typeDef = TypeDef("LenientUri", Imports("docspell.common.LenientUri")))
      case "accountsource" =>
        field =>
          field
            .copy(typeDef =
              TypeDef("AccountSource", Imports("docspell.common.AccountSource"))
            )
      case "itemquery" =>
        field =>
          field
            .copy(typeDef =
              TypeDef(
                "ItemQuery",
                Imports(
                  "docspell.query.ItemQuery",
                  "docspell.restapi.codec.ItemQueryJson._"
                )
              )
            )
      case "channeltype" =>
        field =>
          field.copy(typeDef =
            TypeDef("ChannelType", Imports("docspell.notification.api.ChannelType"))
          )
      case "eventtype" =>
        field =>
          field.copy(typeDef =
            TypeDef("EventType", Imports("docspell.notification.api.EventType"))
          )
      case "jsonminiq" =>
        field =>
          field.copy(typeDef =
            TypeDef("JsonMiniQuery", Imports("docspell.jsonminiq.JsonMiniQuery"))
          )
      case "downloadalltype" =>
        field =>
          field.copy(typeDef =
            TypeDef("DownloadAllType", Imports("docspell.common.DownloadAllType"))
          )
      case "bytesize" =>
        field =>
          field.copy(typeDef = TypeDef("ByteSize", Imports("docspell.common.ByteSize")))
      case "downloadstate" =>
        field =>
          field.copy(typeDef =
            TypeDef("DownloadState", Imports("docspell.common.DownloadState"))
          )
      case "addon-trigger-type" =>
        field =>
          field.copy(typeDef =
            TypeDef("AddonTriggerType", Imports("docspell.addons.AddonTriggerType"))
          )
      case "addon-runner-type" =>
        field =>
          field
            .copy(typeDef = TypeDef("RunnerType", Imports("docspell.addons.RunnerType")))
    })
)

// --- Modules

val loggingApi = project
  .in(file("modules/logging/api"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-logging-api",
    libraryDependencies ++=
      Dependencies.catsEffect ++
        Dependencies.circeCore ++
        Dependencies.fs2Core ++
        Dependencies.sourcecode
  )

val loggingScribe = project
  .in(file("modules/logging/scribe"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-logging-scribe",
    libraryDependencies ++=
      Dependencies.scribe ++
        Dependencies.catsEffect ++
        Dependencies.circeCore ++
        Dependencies.fs2Core
  )
  .dependsOn(loggingApi)

// Base module, everything depends on this – including restapi and
// joexapi modules. This should aim to have least possible
// dependencies
val common = project
  .in(file("modules/common"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-common",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.circe ++
        Dependencies.circeGenericExtra ++
        Dependencies.calevCore ++
        Dependencies.calevCirce
  )
  .dependsOn(loggingApi)

// Some example files for testing
// https://file-examples.com/index.php/sample-documents-download/sample-doc-download/
val files = project
  .in(file("modules/files"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-files",
    libraryDependencies ++=
      Dependencies.tika ++
        Dependencies.icu4j,
    Test / sourceGenerators += Def.task {
      val base = (Test / resourceDirectory).value
      val files = (base ** (_.isFile)).pair(sbt.io.Path.relativeTo(base))
      val lines = files.toList.map(_._2).map { s =>
        val ident = s.replaceAll("[^a-zA-Z0-9_]+", "_")
        val sanitized = s.replace('\\', '/')
        ident -> s"""val $ident = createUrl("$sanitized")"""
      }
      val content = s"""package docspell.files

object ExampleFiles extends ExampleFilesSupport {

${lines.map(_._2).mkString("\n")}

val all = List(
${lines.map(_._1).mkString(",\n")}
)

}
"""
      val target = (Test / sourceManaged).value / "scala" / "ExampleFiles.scala"
      IO.createDirectory(target.getParentFile)
      IO.write(target, content)
      Seq(target)
    }.taskValue
  )
  .dependsOn(common, loggingScribe)

val query =
  crossProject(JSPlatform, JVMPlatform)
    .withoutSuffixFor(JVMPlatform)
    .in(file("modules/query"))
    .disablePlugins(RevolverPlugin)
    .settings(sharedSettings)
    .withTestSettings
    .settings(
      name := "docspell-query",
      libraryDependencies +=
        Dependencies.catsParseJS.value,
      libraryDependencies +=
        Dependencies.scalaJavaTime.value
    )
    .jsSettings(
      Test / fork := false
    )
    .jvmSettings(
      libraryDependencies +=
        Dependencies.scalaJsStubs
    )

val totp = project
  .in(file("modules/totp"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-totp",
    libraryDependencies ++=
      Dependencies.javaOtp ++
        Dependencies.scodecBits ++
        Dependencies.fs2 ++
        Dependencies.circe
  )

val jsonminiq = project
  .in(file("modules/jsonminiq"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-jsonminiq",
    libraryDependencies ++=
      Dependencies.circeCore ++
        Dependencies.catsParse ++
        Dependencies.circe.map(_ % Test)
  )

val notificationApi = project
  .in(file("modules/notification/api"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-notification-api",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.emilCommon ++
        Dependencies.circeGenericExtra
  )
  .dependsOn(common, loggingScribe)

val addonlib = project
  .in(file("modules/addonlib"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.circe ++
        Dependencies.circeYaml
  )
  .dependsOn(common, files, loggingScribe)

val ftsclient = project
  .in(file("modules/fts-client"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-fts-client",
    libraryDependencies ++= Seq.empty
  )
  .dependsOn(common, loggingScribe)

val store = project
  .in(file("modules/store"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-store",
    libraryDependencies ++=
      Dependencies.doobie ++
        Dependencies.binny ++
        Dependencies.tika ++
        Dependencies.fs2 ++
        Dependencies.databases ++
        Dependencies.flyway ++
        Dependencies.emil ++
        Dependencies.emilDoobie ++
        Dependencies.calevCore ++
        Dependencies.calevFs2,
    libraryDependencies ++=
      Dependencies.testContainer.map(_ % Test)
  )
  .dependsOn(
    common,
    addonlib,
    query.jvm,
    totp,
    files,
    notificationApi,
    jsonminiq,
    ftsclient,
    loggingScribe
  )

val notificationImpl = project
  .in(file("modules/notification/impl"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-notification-impl",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.emil ++
        Dependencies.emilMarkdown ++
        Dependencies.http4sClient ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.yamusca ++
        Dependencies.yamuscaCirce
  )
  .dependsOn(notificationApi, store, jsonminiq)

val pubsubApi = project
  .in(file("modules/pubsub/api"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-pubsub-api",
    libraryDependencies ++=
      Dependencies.fs2
  )
  .dependsOn(common)

val pubsubNaive = project
  .in(file("modules/pubsub/naive"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-pubsub-naive",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.http4sClient ++
        Dependencies.circe
  )
  .dependsOn(common, pubsubApi, store % "compile->compile;test->test")

val schedulerApi = project
  .in(file("modules/scheduler/api"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-scheduler-api",
    libraryDependencies ++=
      Dependencies.fs2Core ++
        Dependencies.circeCore
  )
  .dependsOn(loggingApi, common, pubsubApi)

val schedulerImpl = project
  .in(file("modules/scheduler/impl"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-scheduler-impl"
  )
  .dependsOn(
    store % "compile->compile;test->test",
    schedulerApi,
    notificationApi,
    pubsubApi
  )

val extract = project
  .in(file("modules/extract"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-extract",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.twelvemonkeys ++
        Dependencies.pdfbox ++
        Dependencies.poi ++
        Dependencies.commonsIO
  )
  .dependsOn(common, loggingScribe, files % "compile->compile;test->test")

val convert = project
  .in(file("modules/convert"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(
    name := "docspell-convert",
    libraryDependencies ++=
      Dependencies.flexmark ++
        Dependencies.twelvemonkeys ++
        Dependencies.pdfbox
  )
  .dependsOn(common, files % "compile->compile;test->test")

val analysis = project
  .in(file("modules/analysis"))
  .disablePlugins(RevolverPlugin)
  .enablePlugins(NerModelsPlugin)
  .settings(sharedSettings)
  .withTestSettingsDependsOn(loggingScribe)
  .settings(NerModelsPlugin.nerClassifierSettings)
  .settings(
    name := "docspell-analysis",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.stanfordNlpCore
  )
  .dependsOn(common, files % "test->test", loggingScribe)

val ftssolr = project
  .in(file("modules/fts-solr"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-fts-solr",
    libraryDependencies ++=
      Dependencies.http4sClient ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.circe
  )
  .dependsOn(common, ftsclient)

val ftspsql = project
  .in(file("modules/fts-psql"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-fts-psql",
    libraryDependencies ++=
      Dependencies.doobie ++
        Dependencies.postgres ++
        Dependencies.flyway
  )
  .dependsOn(common, ftsclient, store % "compile->compile;test->test")

val restapi = project
  .in(file("modules/restapi"))
  .disablePlugins(RevolverPlugin)
  .enablePlugins(OpenApiSchema)
  .settings(sharedSettings)
  .withTestSettings
  .settings(openapiScalaSettings)
  .settings(
    name := "docspell-restapi",
    libraryDependencies ++=
      Dependencies.circe ++ Dependencies.emil,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.restapi.model"),
    openapiSpec := (Compile / resourceDirectory).value / "docspell-openapi.yml",
    openapiStaticGen := OpenApiDocGenerator.Redoc,
    openapiRedoclyCmd := Seq("redocly-cli"),
    openapiRedoclyConfig := Some(
      (LocalRootProject / baseDirectory).value / "project" / "redocly.yml"
    )
  )
  .dependsOn(common, query.jvm, notificationApi, jsonminiq, addonlib)

val joexapi = project
  .in(file("modules/joexapi"))
  .disablePlugins(RevolverPlugin)
  .enablePlugins(OpenApiSchema)
  .settings(sharedSettings)
  .withTestSettings
  .settings(openapiScalaSettings)
  .settings(
    name := "docspell-joexapi",
    libraryDependencies ++=
      Dependencies.circe ++
        Dependencies.http4sCirce ++
        Dependencies.http4sClient,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("docspell.joexapi.model"),
    openapiSpec := (Compile / resourceDirectory).value / "joex-openapi.yml",
    openapiStaticGen := OpenApiDocGenerator.Redoc,
    openapiRedoclyCmd := Seq("redocly-cli"),
    openapiRedoclyConfig := Some(
      (LocalRootProject / baseDirectory).value / "project" / "redocly.yml"
    )
  )
  .dependsOn(common, loggingScribe, addonlib)

val backend = project
  .in(file("modules/backend"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-backend",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.bcrypt ++
        Dependencies.http4sClient ++
        Dependencies.emil
  )
  .dependsOn(
    addonlib,
    store,
    notificationApi,
    joexapi,
    ftsclient,
    totp,
    pubsubApi,
    loggingApi,
    schedulerApi
  )

val oidc = project
  .in(file("modules/oidc"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-oidc",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.http4sClient ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.circe ++
        Dependencies.jwtScala
  )
  .dependsOn(common, loggingScribe)

val webapp = project
  .in(file("modules/webapp"))
  .disablePlugins(RevolverPlugin)
  .enablePlugins(OpenApiSchema, StylesPlugin)
  .settings(sharedSettings)
  .settings(elmSettings)
  .settings(stylesSettings)
  .settings(webjarSettings(query.js))
  .settings(
    name := "docspell-webapp",
    openapiTargetLanguage := Language.Elm,
    openapiPackage := Pkg("Api.Model"),
    openapiSpec := (restapi / Compile / resourceDirectory).value / "docspell-openapi.yml",
    openapiElmConfig := ElmConfig().withJson(ElmJson.decodePipeline)
  )
  .dependsOn(query.js)

// Config project shared among the two applications only
val config = project
  .in(file("modules/config"))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .withTestSettings
  .settings(
    name := "docspell-config",
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.pureconfig
  )
  .dependsOn(common, loggingApi, ftspsql, store, addonlib)

// --- Application(s)

val joex = project
  .in(file("modules/joex"))
  .enablePlugins(
    BuildInfoPlugin,
    JavaServerAppPackaging,
    DebianPlugin,
    SystemdPlugin,
    ClasspathJarPlugin
  )
  .settings(sharedSettings)
  .withTestSettings
  .settings(debianSettings("docspell-joex"))
  .settings(buildInfoSettings)
  .settings(
    name := "docspell-joex",
    description := "The joex component (job executor) for docspell which executes long-running tasks.",
    packageSummary := "Docspell Joex",
    packageDescription := description.value,
    libraryDependencies ++=
      Dependencies.fs2 ++
        Dependencies.http4sServer ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.circe ++
        Dependencies.pureconfig ++
        Dependencies.pureconfigIp4s ++
        Dependencies.emilTnef ++
        Dependencies.poi ++
        Dependencies.emilMarkdown ++
        Dependencies.emilJsoup ++
        Dependencies.jsoup ++
        Dependencies.yamusca,
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.joex",
    reStart / javaOptions ++= Seq(
      s"-Dconfig.file=${(LocalRootProject / baseDirectory).value / "local" / "dev.conf"}",
      "-Xmx1596M",
      "-XX:+UseG1GC"
    ),
    Revolver.enableDebugging(port = 5051, suspend = false)
  )
  .dependsOn(
    config,
    loggingApi,
    loggingScribe,
    store,
    backend,
    extract,
    convert,
    analysis,
    joexapi,
    restapi,
    ftssolr,
    ftspsql,
    pubsubNaive,
    notificationImpl,
    schedulerImpl
  )

val restserver = project
  .in(file("modules/restserver"))
  .enablePlugins(
    BuildInfoPlugin,
    JavaServerAppPackaging,
    DebianPlugin,
    SystemdPlugin,
    ClasspathJarPlugin
  )
  .settings(sharedSettings)
  .withTestSettings
  .settings(debianSettings("docspell-server"))
  .settings(buildInfoSettings)
  .settings(
    name := "docspell-restserver",
    description := "Docspell server providing the user interface and a REST Api.",
    packageSummary := "Docspell Rest server",
    packageDescription := description.value,
    libraryDependencies ++=
      Dependencies.http4sServer ++
        Dependencies.http4sCirce ++
        Dependencies.http4sDsl ++
        Dependencies.circe ++
        Dependencies.pureconfig ++
        Dependencies.pureconfigIp4s ++
        Dependencies.yamusca ++
        Dependencies.kittens ++
        Dependencies.webjars,
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "docspell.restserver",
    Compile / sourceGenerators += Def.task {
      createWebjarSource(Dependencies.webjars, (Compile / sourceManaged).value)
    }.taskValue,
    Compile / resourceGenerators += Def.task {
      copyWebjarResources(
        Seq((restapi / Compile / resourceDirectory).value / "docspell-openapi.yml"),
        (Compile / resourceManaged).value,
        name.value,
        version.value,
        streams.value.log
      )
    }.taskValue,
    Compile / unmanagedResourceDirectories ++= Seq(
      (Compile / resourceDirectory).value.getParentFile / "templates"
    ),
    reStart / javaOptions ++= Seq(
      s"-Dconfig.file=${(LocalRootProject / baseDirectory).value / "local" / "dev.conf"}",
      "-Xmx150M",
      "-XX:+UseG1GC"
    ),
    Revolver.enableDebugging(port = 5050, suspend = false),
    Universal / mappings := {
      val allMappings = (Universal / mappings).value
      allMappings.filter {
        // scalajs artifacts are not needed at runtime
        case (file, name) => !name.contains("_sjs1_")
      }
    }
  )
  .dependsOn(
    config,
    loggingApi,
    loggingScribe,
    restapi,
    joexapi,
    backend,
    webapp,
    ftssolr,
    ftspsql,
    oidc,
    pubsubNaive,
    notificationImpl,
    schedulerImpl
  )

// --- Website Documentation

val website = project
  .in(file("website"))
  .disablePlugins(RevolverPlugin, ReleasePlugin)
  .enablePlugins(ZolaPlugin, GitHubPagesPlugin)
  .settings(sharedSettings)
  .settings(
    name := "docspell-website",
    publishArtifact := false,
    publish / skip := true,
    gitHubPagesOrgName := "eikek",
    gitHubPagesRepoName := "docspell",
    gitHubPagesSiteDir := zolaOutputDir.value,
    Compile / resourceGenerators += Def.task {
      val templateOut = baseDirectory.value / "site" / "templates" / "shortcodes"
      val staticOut = baseDirectory.value / "site" / "static" / "openapi"
      IO.createDirectories(Seq(templateOut, staticOut))

      val files = Seq(
        (restserver / Compile / resourceDirectory).value / "reference.conf" -> templateOut / "server.conf",
        (joex / Compile / resourceDirectory).value / "reference.conf" -> templateOut / "joex.conf",
        (LocalRootProject / baseDirectory).value / "tools" / "exim" / "exim.conf" -> templateOut / "sample-exim.conf",
        (restapi / Compile / resourceDirectory).value / "docspell-openapi.yml" -> staticOut / "docspell-openapi.yml",
        (restapi / Compile / openapiStaticDoc).value -> staticOut / "docspell-openapi.html"
      )
      IO.copy(files)
      files.map(_._2)
    }.taskValue,
    Compile / resourceGenerators += Def.task {
      val templateOut =
        baseDirectory.value / "site" / "templates" / "shortcodes" / "config.env.txt"
      val files = List(
        (restserver / Compile / resourceDirectory).value / "reference.conf",
        (joex / Compile / resourceDirectory).value / "reference.conf"
      )
      val cfg = EnvConfig.makeConfig(files)
      EnvConfig.serializeTo(cfg, templateOut)
      Seq(templateOut)
    }.taskValue,
    Compile / resourceGenerators += Def.task {
      val changelog = (LocalRootProject / baseDirectory).value / "Changelog.md"
      val targetDir = baseDirectory.value / "site" / "content" / "docs" / "install"
      IO.createDirectory(targetDir)
      val target = targetDir / "changelog.md"

      IO.write(
        target,
        """|+++
           |title = "Changelog"
           |description = "See what changed between releases."
           |weight = 10000
           |insert_anchor_links = "right"
           |+++
           |""".stripMargin
      )
      IO.append(target, IO.readBytes(changelog))
      Seq(target)
    }.taskValue,
    zolaPrepare := {
      val log = streams.value.log
      log.info("Generating examples…")
      val templateOut = baseDirectory.value / "site" / "templates" / "shortcodes"
      IO.createDirectory(templateOut)

      // sbt crashes when interpolating values into the string in `toTask`
      // this is the reason for the followingy construct…
      (Compile / run).toTask(s" addon-output /tmp/addon-output.json").value
      (Compile / run).toTask(s" item-data /tmp/item-data.json").value
      (Compile / run).toTask(s" item-args /tmp/item-args.json").value
      (Compile / run).toTask(s" file-meta /tmp/file-meta.json").value

      val inputs = List("addon-output", "item-data", "item-args", "file-meta")

      inputs.foreach { name =>
        IO.move(file(s"/tmp/$name.json"), templateOut / name)
      }
    }
  )
  .dependsOn(addonlib, joex)

val root = project
  .in(file("."))
  .disablePlugins(RevolverPlugin)
  .settings(sharedSettings)
  .settings(noPublish)
  .settings(
    name := "docspell-root"
  )
  .aggregate(
    common,
    addonlib,
    loggingApi,
    loggingScribe,
    config,
    extract,
    convert,
    analysis,
    ftsclient,
    ftssolr,
    ftspsql,
    files,
    store,
    joexapi,
    joex,
    backend,
    webapp,
    restapi,
    restserver,
    query.jvm,
    query.js,
    jsonminiq,
    totp,
    oidc,
    pubsubApi,
    pubsubNaive,
    notificationApi,
    notificationImpl,
    schedulerApi,
    schedulerImpl
  )

// --- Helpers

def copyWithGZ(src: File, target: File): Seq[File] = {
  val gzipFilter = "*.html" || "*.css" || "*.js"
  IO.copy(Seq(src -> target))
  if (gzipFilter.accept(src)) {
    val gz = file(target.toString + ".gz")
    IO.gzip(src, gz)
    Seq(target, gz)
  } else {
    Seq(target)
  }
}

def copyWebjarResources(
    src: Seq[File],
    base: File,
    artifact: String,
    version: String,
    logger: Logger
): Seq[File] = {
  val targetDir = base / "META-INF" / "resources" / "webjars" / artifact / version
  logger.info(s"Copy webjar resources from ${src.size} files/directories.")
  src.flatMap { dir =>
    if (dir.isDirectory) {
      val files = (dir ** "*").filter(_.isFile).get.pair(Path.relativeTo(dir))
      files.flatMap { case (f, name) =>
        val target = targetDir / name
        IO.createDirectories(Seq(target.getParentFile))
        copyWithGZ(f, target)
      }
    } else {
      val target = targetDir / dir.name
      IO.createDirectories(Seq(target.getParentFile))
      copyWithGZ(dir, target)
    }
  }
}

def compileElm(
    logger: Logger,
    wd: File,
    outBase: File,
    artifact: String,
    version: String,
    mode: ElmCompileMode
): Seq[File] = {
  logger.info("Compile elm files ...")
  val target =
    outBase / "META-INF" / "resources" / "webjars" / artifact / version / "docspell-app.js"
  val cmd = (Seq("elm", "make")
    ++ mode.flags
    ++ Seq("--output", target.toString)
    ++ Seq(wd / "src" / "main" / "elm" / "Main.elm").map(_.toString))
  Cmd.run(cmd, wd, logger)
  val targetGZ = file(target.toString + ".gz")
  IO.gzip(target, targetGZ)
  Seq(target, targetGZ)
}

def createWebjarSource(wj: Seq[ModuleID], out: File): Seq[File] = {
  val target = out / "Webjars.scala"
  val badChars = "-.".toSet
  val fields = wj
    .map(m =>
      s"""val ${m.name.toLowerCase.filter(c =>
          !badChars.contains(c)
        )} = "/${m.name}/${m.revision}" """
    )
    .mkString("\n\n")
  val content = s"""package docspell.restserver.webapp
                   |object Webjars {
                   |$fields
                   |}
                   |""".stripMargin

  IO.write(target, content)
  Seq(target)
}

def packageTools(logger: Logger, dir: File, version: String): Seq[File] = {
  val target = dir / "target"
  IO.delete(target)
  IO.createDirectory(target)
  val archive = target / s"docspell-tools-$version.zip"
  logger.info(s"Packaging tools to $archive ...")
  val webext = target / "docspell-firefox-extension.xpi"
  val wx = dir / "webextension"
  IO.zip(
    Seq(
      wx / "_locales/de/messages.json" -> "_locales/de/messages.json",
      wx / "_locales/en/messages.json" -> "_locales/en/messages.json",
      wx / "docspell.js" -> "docspell.js",
      wx / "icons" / "logo-48.png" -> "icons/logo-48.png",
      wx / "icons" / "logo-96.png" -> "icons/logo-96.png",
      wx / "manifest.json" -> "manifest.json"
    ),
    webext,
    None
  )

  val excludes = Seq(wx, target)

  val files =
    (dir ** "*")
      .filter(f => !excludes.exists(p => f.absolutePath.startsWith(p.absolutePath)))
      .pair(sbt.io.Path.relativeTo(dir))
      .map { case (f, name) => (f, s"docspell-tools-$version/$name") }

  IO.zip(
    Seq(
      webext -> s"docspell-tools-$version/firefox/docspell-extension.xpi",
      wx / "native/app_manifest.json" -> s"docspell-tools-$version/firefox/native/app_manifest.json",
      wx / "native/native.py" -> s"docspell-tools-$version/firefox/native/native.py"
    ) ++ files,
    archive,
    None
  )

  Seq(archive)
}

// --- aliases

addCommandAlias(
  "make",
  ";set webapp/elmCompileMode := ElmCompileMode.Production; set webapp/stylesMode := StylesMode.Prod ;root/openapiCodegen ;root/Test/compile"
)
addCommandAlias("make-zip", ";restserver/Universal/packageBin ;joex/Universal/packageBin")
addCommandAlias("make-deb", ";restserver/Debian/packageBin ;joex/Debian/packageBin")
addCommandAlias("make-tools", ";root/toolsPackage")
addCommandAlias("make-pkg", ";clean ;make ;make-zip ;make-deb")

addCommandAlias("ci", "make; lint; test")
addCommandAlias(
  "lint",
  "restapi/openapiLint; joexapi/openapiLint; headerCheck; scalafmtSbtCheck; scalafmtCheckAll; Compile/scalafix --check; Test/scalafix --check"
)
addCommandAlias(
  "fix",
  "headerCreateAll; Compile/scalafix; Test/scalafix; scalafmtSbt; scalafmtAll"
)
addCommandAlias("make-website", ";website/clean ;website/zolaBuild ;website/zolaCheck")
addCommandAlias("publish-website", "website/publishToGitHubPages")
