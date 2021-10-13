package docspell.build

import sbt._
import org.portablescala.sbtplatformdeps.PlatformDepsPlugin.autoImport._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BinnyVersion = "0.1.0"
  val CalevVersion = "0.6.0"
  val CatsParseVersion = "0.3.4"
  val CirceVersion = "0.14.1"
  val ClipboardJsVersion = "2.0.6"
  val DoobieVersion = "1.0.0-RC1"
  val EmilVersion = "0.10.0-M3"
  val FlexmarkVersion = "0.62.2"
  val FlywayVersion = "8.0.1"
  val Fs2Version = "3.1.5"
  val Fs2CronVersion = "0.7.1"
  val H2Version = "1.4.200"
  val Http4sVersion = "0.23.4"
  val Icu4jVersion = "69.1"
  val javaOtpVersion = "0.3.0"
  val JsoupVersion = "1.14.3"
  val JwtScalaVersion = "9.0.2"
  val KindProjectorVersion = "0.10.3"
  val KittensVersion = "2.3.2"
  val LevigoJbig2Version = "2.0"
  val Log4sVersion = "1.10.0"
  val LogbackVersion = "1.2.6"
  val MariaDbVersion = "2.7.4"
  val MUnitVersion = "0.7.29"
  val MUnitCatsEffectVersion = "1.0.6"
  val OrganizeImportsVersion = "0.5.0"
  val PdfboxVersion = "2.0.24"
  val PoiVersion = "4.1.2"
  val PostgresVersion = "42.2.24"
  val PureConfigVersion = "0.17.0"
  val ScalaJavaTimeVersion = "2.3.0"
  val ScodecBitsVersion = "1.1.29"
  val Slf4jVersion = "1.7.32"
  val StanfordNlpVersion = "4.2.2"
  val TikaVersion = "2.1.0"
  val YamuscaVersion = "0.8.1"
  val SwaggerUIVersion = "3.52.3"
  val TestContainerVersion = "0.39.8"
  val TwelveMonkeysVersion = "3.7.0"
  val JQueryVersion = "3.5.1"
  val ViewerJSVersion = "0.5.9"

  val jwtScala = Seq(
    "com.github.jwt-scala" %% "jwt-circe" % JwtScalaVersion
  )

  val scodecBits = Seq(
    "org.scodec" %% "scodec-bits" % ScodecBitsVersion
  )

  val javaOtp = Seq(
    "com.eatthepath" % "java-otp" % "0.3.0"
  )

  val testContainer = Seq(
    "com.dimafeng" %% "testcontainers-scala-munit" % TestContainerVersion,
    "com.dimafeng" %% "testcontainers-scala-mariadb" % TestContainerVersion,
    "com.dimafeng" %% "testcontainers-scala-postgresql" % TestContainerVersion
  )

  val catsParse = Seq(
    "org.typelevel" %% "cats-parse" % CatsParseVersion
  )
  val catsParseJS =
    Def.setting("org.typelevel" %%% "cats-parse" % CatsParseVersion)

  val scalaJsStubs =
    "org.scala-js" %% "scalajs-stubs" % "1.1.0" % "provided"

  val catsJS = Def.setting("org.typelevel" %%% "cats-core" % "2.4.2")

  val scalaJavaTime =
    Def.setting("io.github.cquiroz" %%% "scala-java-time" % ScalaJavaTimeVersion)

  val kittens = Seq(
    "org.typelevel" %% "kittens" % KittensVersion
  )

  val calevCore = Seq(
    "com.github.eikek" %% "calev-core" % CalevVersion
  )
  val calevFs2 = Seq(
    "eu.timepit" %% "fs2-cron-calev" % Fs2CronVersion
  )
  val calevCirce = Seq(
    "com.github.eikek" %% "calev-circe" % CalevVersion
  )

  val jclOverSlf4j = Seq(
    "org.slf4j" % "jcl-over-slf4j" % Slf4jVersion
  )
  val julOverSlf4j = Seq(
    "org.slf4j" % "jul-to-slf4j" % Slf4jVersion
  )

  val poi = Seq(
    "org.apache.poi" % "poi" % PoiVersion,
    "org.apache.poi" % "poi-ooxml" % PoiVersion,
    "org.apache.poi" % "poi-scratchpad" % PoiVersion
  ).map(
    _.excludeAll(
      ExclusionRule("commons-logging")
    )
  ) ++ jclOverSlf4j

  // https://github.com/vsch/flexmark-java
  // BSD 2-Clause
  val flexmark = Seq(
    "com.vladsch.flexmark" % "flexmark" % FlexmarkVersion,
    "com.vladsch.flexmark" % "flexmark-ext-tables" % FlexmarkVersion,
    "com.vladsch.flexmark" % "flexmark-ext-gfm-strikethrough" % FlexmarkVersion
  ).map(
    _.excludeAll(
      ExclusionRule("junit"),
      ExclusionRule("hamcrest-core")
    )
  )

  val twelvemonkeys = Seq(
    "com.twelvemonkeys.imageio" % "imageio-jpeg" % TwelveMonkeysVersion,
    "com.twelvemonkeys.imageio" % "imageio-tiff" % TwelveMonkeysVersion
  )

  val levigoJbig2 = Seq(
    "com.levigo.jbig2" % "levigo-jbig2-imageio" % LevigoJbig2Version
  )

  val pdfbox = Seq(
    ("org.apache.pdfbox" % "pdfbox" % PdfboxVersion).excludeAll(
      ExclusionRule("org.bouncycastle"),
      ExclusionRule("commons-logging")
    )
  ) ++ jclOverSlf4j ++ levigoJbig2

  val emilCommon = Seq(
    "com.github.eikek" %% "emil-common" % EmilVersion
  )
  val emil = Seq(
    "com.github.eikek" %% "emil-common" % EmilVersion,
    "com.github.eikek" %% "emil-javamail" % EmilVersion
  )
  val emilDoobie = Seq(
    "com.github.eikek" %% "emil-doobie" % EmilVersion
  )
  val emilTnef = Seq(
    ("com.github.eikek" %% "emil-tnef" % EmilVersion).excludeAll(
      ExclusionRule("org.apache.poi")
    )
  )
  val emilMarkdown = Seq(
    "com.github.eikek" %% "emil-markdown" % EmilVersion
  )
  val emilJsoup = Seq(
    "com.github.eikek" %% "emil-jsoup" % EmilVersion
  )

  val jsoup = Seq(
    "org.jsoup" % "jsoup" % JsoupVersion
  )

  val stanfordNlpCore = Seq(
    ("edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion).excludeAll(
      ExclusionRule("com.io7m.xom", "xom"),
      ExclusionRule("javax.servlet", "javax.servlet-api"),
      ExclusionRule("org.apache.lucene", "lucene-queryparser"),
      ExclusionRule("org.apache.lucene", "lucene-queries"),
      ExclusionRule("org.apache.lucene", "lucene-analyzers-common"),
      ExclusionRule("org.apache.lucene", "lucene-core"),
      ExclusionRule("com.sun.xml.bind", "jaxb-impl"),
      ExclusionRule("com.sun.xml.bind", "jaxb-core"),
      ExclusionRule("javax.xml.bind", "jaxb-api"),
      ExclusionRule("javax.activation"),
      ExclusionRule("de.jollyday", "jollyday"),
      ExclusionRule("com.apple", "AppleJavaExtensions"),
      ExclusionRule("org.glassfish", "javax.json")
    )
  )

  val stanfordNlpModels = Seq(
    ("edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion)
      .classifier("models"),
    ("edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion)
      .classifier("models-german"),
    ("edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion)
      .classifier("models-french"),
    ("edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion)
      .classifier(
        "models-english"
      )
  )

  val tika = Seq(
    "org.apache.tika" % "tika-core" % TikaVersion
  )
  val commonsIO = Seq(
    "commons-io" % "commons-io" % "2.11.0"
  )
  val tikaParser = Seq(
    "org.apache.tika" % "tika-parsers" % TikaVersion
  )

  val bcrypt = Seq(
    "org.mindrot" % "jbcrypt" % BcryptVersion
  )

  val fs2 = Seq(
    "co.fs2" %% "fs2-core" % Fs2Version,
    "co.fs2" %% "fs2-io" % Fs2Version
  )

  val http4sClient = Seq(
    "org.http4s" %% "http4s-blaze-client" % Http4sVersion
  )

  val http4sCirce = Seq(
    "org.http4s" %% "http4s-circe" % Http4sVersion
  )

  val http4sDsl = Seq(
    "org.http4s" %% "http4s-dsl" % Http4sVersion
  )

  val http4sServer = Seq(
    "org.http4s" %% "http4s-blaze-server" % Http4sVersion
  )

  val circe = Seq(
    "io.circe" %% "circe-generic" % CirceVersion,
    "io.circe" %% "circe-parser" % CirceVersion
  )

  // https://github.com/Log4s/log4s;ASL 2.0
  val loggingApi = Seq(
    "org.log4s" %% "log4s" % Log4sVersion
  )

  val logging = Seq(
    "ch.qos.logback" % "logback-classic" % LogbackVersion
  )

  // https://github.com/melrief/pureconfig
  // MPL 2.0
  val pureconfig = Seq(
    "com.github.pureconfig" %% "pureconfig" % PureConfigVersion
  )

  // https://github.com/h2database/h2database
  // MPL 2.0 or EPL 1.0
  val h2 = Seq(
    "com.h2database" % "h2" % H2Version
  )
  val mariadb = Seq(
    "org.mariadb.jdbc" % "mariadb-java-client" % MariaDbVersion
  )
  val postgres = Seq(
    "org.postgresql" % "postgresql" % PostgresVersion
  )
  val databases = h2 ++ mariadb ++ postgres

  // https://github.com/tpolecat/doobie
  // MIT
  val doobie = Seq(
    "org.tpolecat" %% "doobie-core" % DoobieVersion,
    "org.tpolecat" %% "doobie-hikari" % DoobieVersion
  )

  val binny = Seq(
    "com.github.eikek" %% "binny-core" % BinnyVersion,
    "com.github.eikek" %% "binny-jdbc" % BinnyVersion
  )

  // https://github.com/flyway/flyway
  // ASL 2.0
  val flyway = Seq(
    "org.flywaydb" % "flyway-core" % FlywayVersion
  )

  val yamusca = Seq(
    "com.github.eikek" %% "yamusca-core" % YamuscaVersion
  )

  val munit = Seq(
    "org.scalameta" %% "munit" % MUnitVersion,
    "org.scalameta" %% "munit-scalacheck" % MUnitVersion,
    "org.typelevel" %% "munit-cats-effect-3" % MUnitCatsEffectVersion
  )

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector" % KindProjectorVersion
  val betterMonadicFor = "com.olegpy" %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars" % "swagger-ui" % SwaggerUIVersion,
    "org.webjars" % "viewerjs" % ViewerJSVersion,
    "org.webjars" % "clipboard.js" % ClipboardJsVersion
  )

  val icu4j = Seq(
    "com.ibm.icu" % "icu4j" % Icu4jVersion
  )

  val organizeImports = Seq(
    "com.github.liancheng" %% "organize-imports" % OrganizeImportsVersion
  )
}
