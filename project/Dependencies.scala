package docspell.build

import sbt._
import org.portablescala.sbtplatformdeps.PlatformDepsPlugin.autoImport._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BinnyVersion = "0.11.0"
  val CalevVersion = "0.7.3"
  val CatsVersion = "2.10.0"
  val CatsEffectVersion = "3.5.4"
  val CatsParseVersion = "1.0.0"
  val CirceVersion = "0.15.0-M1"
  val CirceGenericExtrasVersion = "0.14.3"
  val CirceYamlVersion = "0.15.3"
  val ClipboardJsVersion = "2.0.11"
  val DoobieVersion = "1.0.0-RC5"
  val EmilVersion = "0.17.0"
  val FlexmarkVersion = "0.64.8"
  val FlywayVersion = "10.13.0"
  val Fs2Version = "3.10.2"
  val H2Version = "2.2.224"
  val Http4sVersion = "0.23.27"
  val Icu4jVersion = "75.1"
  val JavaOtpVersion = "0.4.0"
  val JsoupVersion = "1.18.1"
  val JwtScalaVersion = "10.0.1"
  val KindProjectorVersion = "0.10.3"
  val KittensVersion = "3.3.0"
  val LevigoJbig2Version = "2.0"
  val Log4sVersion = "1.10.0"
  val LogbackVersion = "1.2.10"
  val MariaDbVersion = "3.4.1"
  val MUnitVersion = "1.0.0"
  val MUnitCatsEffectVersion = "2.0.0"
  val PdfboxVersion = "3.0.2"
  val PdfjsViewerVersion = "2.12.313"
  val PoiVersion = "4.1.2"
  val PostgresVersion = "42.7.3"
  val PureConfigVersion = "0.17.7"
  val ScalaJavaTimeVersion = "2.6.0"
  val ScodecBitsVersion = "1.2.0"
  val ScribeVersion = "3.15.0"
  val Slf4jVersion = "2.0.13"
  val SourcecodeVersion = "0.4.2"
  val StanfordNlpVersion = "4.5.7"
  val TikaVersion = "2.9.2"
  val YamuscaVersion = "0.10.0"
  val SwaggerUIVersion = "5.17.14"
  val TestContainerVersion = "0.41.4"
  val TwelveMonkeysVersion = "3.11.0"
  val JQueryVersion = "3.5.1"

  val scribe = Seq(
    "com.outr" %% "scribe" % ScribeVersion,
    "com.outr" %% "scribe-slf4j2" % ScribeVersion
  )

  val sourcecode = Seq(
    "com.lihaoyi" %% "sourcecode" % SourcecodeVersion
  )

  val jwtScala = Seq(
    "com.github.jwt-scala" %% "jwt-circe" % JwtScalaVersion
  )

  val scodecBits = Seq(
    "org.scodec" %% "scodec-bits" % ScodecBitsVersion
  )

  val javaOtp = Seq(
    "com.eatthepath" % "java-otp" % JavaOtpVersion
  )

  val testContainer = Seq(
    "com.dimafeng" %% "testcontainers-scala-munit" % TestContainerVersion,
    "com.dimafeng" %% "testcontainers-scala-mariadb" % TestContainerVersion,
    "com.dimafeng" %% "testcontainers-scala-postgresql" % TestContainerVersion
  )

  val cats = Seq(
    "org.typelevel" %% "cats-core" % CatsVersion
  )

  val catsEffect = Seq(
    "org.typelevel" %% "cats-effect" % CatsEffectVersion
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
    "com.github.eikek" %% "calev-fs2" % CalevVersion
  )
  val calevCirce = Seq(
    "com.github.eikek" %% "calev-circe" % CalevVersion
  )

  val jclOverSlf4j = Seq(
    "org.slf4j" % "jcl-over-slf4j" % Slf4jVersion
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
      ExclusionRule("junit", "junit"),
      ExclusionRule("de.jollyday", "jollyday"),
      ExclusionRule("com.apple", "AppleJavaExtensions"),
      ExclusionRule("org.glassfish", "javax.json")
    )
  )

  val stanfordNlpModels = {
    val artifact = "edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion
    Seq(
      artifact.classifier("models"),
      artifact.classifier("models-german"),
      artifact.classifier("models-french"),
      artifact.classifier("models-english"),
      artifact.classifier("models-spanish")
    )
  }

  val tika = Seq(
    "org.apache.tika" % "tika-core" % TikaVersion
  )
  val commonsIO = Seq(
    "commons-io" % "commons-io" % "2.16.1"
  )
  val tikaParser = Seq(
    "org.apache.tika" % "tika-parsers" % TikaVersion
  )

  val bcrypt = Seq(
    "org.mindrot" % "jbcrypt" % BcryptVersion
  )

  val fs2Core = Seq(
    "co.fs2" %% "fs2-core" % Fs2Version
  )
  val fs2Io = Seq(
    "co.fs2" %% "fs2-io" % Fs2Version
  )
  val fs2 = fs2Core ++ fs2Io

  val http4sClient = Seq(
    "org.http4s" %% "http4s-ember-client" % Http4sVersion
  )

  val http4sCirce = Seq(
    "org.http4s" %% "http4s-circe" % Http4sVersion
  )

  val http4sDsl = Seq(
    "org.http4s" %% "http4s-dsl" % Http4sVersion
  )

  val http4sServer = Seq(
    "org.http4s" %% "http4s-ember-server" % Http4sVersion
  )

  val circeCore = Seq(
    "io.circe" %% "circe-core" % CirceVersion
  )
  val circeParser = Seq(
    "io.circe" %% "circe-parser" % CirceVersion
  )
  val circe =
    circeCore ++ circeParser ++ Seq(
      "io.circe" %% "circe-generic" % CirceVersion
    )
  val circeGenericExtra = circeCore ++ Seq(
    "io.circe" %% "circe-generic-extras" % CirceGenericExtrasVersion
  )
  val circeYaml = circeCore ++ Seq(
    "io.circe" %% "circe-yaml" % CirceYamlVersion
  )

  // https://github.com/melrief/pureconfig
  // MPL 2.0
  val pureconfig = Seq(
    "com.github.pureconfig" %% "pureconfig" % PureConfigVersion
  )

  val pureconfigIp4s = Seq(
    "com.github.pureconfig" %% "pureconfig-ip4s" % PureConfigVersion
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
    "com.github.eikek" %% "binny-jdbc" % BinnyVersion,
    "com.github.eikek" %% "binny-minio" % BinnyVersion,
    "com.github.eikek" %% "binny-fs" % BinnyVersion
  )

  // https://github.com/flyway/flyway
  // ASL 2.0
  val flyway = Seq(
    "org.flywaydb" % "flyway-core" % FlywayVersion,
    "org.flywaydb" % "flyway-database-postgresql" % FlywayVersion,
    "org.flywaydb" % "flyway-mysql" % FlywayVersion
  )

  val yamusca = Seq(
    "com.github.eikek" %% "yamusca-core" % YamuscaVersion,
    "com.github.eikek" %% "yamusca-derive" % YamuscaVersion
  )
  val yamuscaCirce = Seq(
    "com.github.eikek" %% "yamusca-circe" % YamuscaVersion
  )

  val munit = Seq(
    "org.scalameta" %% "munit" % MUnitVersion,
    "org.scalameta" %% "munit-scalacheck" % MUnitVersion,
    "org.typelevel" %% "munit-cats-effect" % MUnitCatsEffectVersion
  )

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector" % KindProjectorVersion
  val betterMonadicFor = "com.olegpy" %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars" % "swagger-ui" % SwaggerUIVersion,
    "org.webjars" % "clipboard.js" % ClipboardJsVersion,
    "org.webjars.npm" % "pdfjs-dist-viewer-min" % PdfjsViewerVersion
  )

  val icu4j = Seq(
    "com.ibm.icu" % "icu4j" % Icu4jVersion
  )

}
