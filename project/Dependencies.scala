package docspell.build

import sbt._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BitpeaceVersion = "0.4.5"
  val CalevVersion = "0.3.0"
  val CirceVersion = "0.13.0"
  val DoobieVersion = "0.9.0"
  val EmilVersion = "0.4.0"
  val FastparseVersion = "2.1.3"
  val FlexmarkVersion = "0.61.0"
  val FlywayVersion = "6.3.3"
  val Fs2Version = "2.3.0"
  val H2Version = "1.4.200"
  val Http4sVersion = "0.21.3"
  val Icu4jVersion = "66.1"
  val KindProjectorVersion = "0.10.3"
  val Log4sVersion = "1.8.2"
  val LogbackVersion = "1.2.3"
  val MariaDbVersion = "2.6.0"
  val MiniTestVersion = "2.8.1"
  val PdfboxVersion = "2.0.19"
  val PoiVersion = "4.1.2"
  val PostgresVersion = "42.2.12"
  val PureConfigVersion = "0.12.3"
  val Slf4jVersion = "1.7.30"
  val SqliteVersion = "3.30.1"
  val StanfordNlpVersion = "3.9.2"
  val TikaVersion = "1.24"
  val YamuscaVersion = "0.6.1"
  val SwaggerUIVersion = "3.25.0"
  val SemanticUIVersion = "2.4.1"
  val TwelveMonkeysVersion = "3.5"
  val JQueryVersion = "3.4.1"
  val ViewerJSVersion = "0.5.8"


  val calevCore = Seq(
    "com.github.eikek" %% "calev-core" % CalevVersion,
  )
  val calevFs2 = Seq(
    "com.github.eikek" %% "calev-fs2" % CalevVersion
  )
  val calev = calevFs2 ++ calevCore

  val jclOverSlf4j = Seq(
    "org.slf4j" % "jcl-over-slf4j" % Slf4jVersion
  )
  val julOverSlf4j = Seq(
    "org.slf4j" % "jul-to-slf4j" % Slf4jVersion
  )

  val poi = Seq(
    "org.apache.poi" % "poi" % PoiVersion,
    "org.apache.poi" % "poi-ooxml" % PoiVersion,
    "org.apache.poi" % "poi-scratchpad" % PoiVersion,
  ).map(_.excludeAll(
    ExclusionRule("commons-logging")
  )) ++ jclOverSlf4j

  // https://github.com/vsch/flexmark-java
  // BSD 2-Clause
  val flexmark = Seq(
    "com.vladsch.flexmark" % "flexmark" % FlexmarkVersion,
    "com.vladsch.flexmark" % "flexmark-ext-tables" % FlexmarkVersion,
    "com.vladsch.flexmark" % "flexmark-ext-gfm-strikethrough" % FlexmarkVersion
  ).map(_.excludeAll(
    ExclusionRule("junit"),
    ExclusionRule("hamcrest-core")
  ))

  val twelvemonkeys = Seq(
    "com.twelvemonkeys.imageio" % "imageio-jpeg" % TwelveMonkeysVersion,
    "com.twelvemonkeys.imageio" % "imageio-tiff" % TwelveMonkeysVersion
  )

  val pdfbox = Seq(
    "org.apache.pdfbox" % "pdfbox" % PdfboxVersion excludeAll (
      ExclusionRule("org.bouncycastle"),
      ExclusionRule("commons-logging")
    )
  ) ++ jclOverSlf4j

  val emil = Seq(
    "com.github.eikek" %% "emil-common" % EmilVersion,
    "com.github.eikek" %% "emil-javamail" % EmilVersion    
  )
  val emilDoobie = Seq(
    "com.github.eikek" %% "emil-doobie" % EmilVersion,
  )
  val emilTnef = Seq(
    "com.github.eikek" %% "emil-tnef" % EmilVersion,
  )

  val stanfordNlpCore = Seq(
    "edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion excludeAll(
      ExclusionRule("com.io7m.xom", "xom"),
      ExclusionRule("javax.servlet", "javax.servlet-api"),
      ExclusionRule("org.apache.lucene", "lucene-queryparser"),
      ExclusionRule("org.apache.lucene", "lucene-queries"),
      ExclusionRule("org.apache.lucene", "lucene-analyzers-common"),
      ExclusionRule("org.apache.lucene", "lucene-core"),
      ExclusionRule("com.sun.xml.bind", "jaxb-impl"),
      ExclusionRule("com.sun.xml.bind", "jaxb-core"),
      ExclusionRule("javax.xml.bind", "jaxb-api"),
      ExclusionRule("de.jollyday", "jollyday"),
      ExclusionRule("com.apple", "AppleJavaExtensions"),
      ExclusionRule("org.glassfish", "javax.json")
    )
  )

  val stanfordNlpModels = Seq(
    "edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion classifier "models-german",
    "edu.stanford.nlp" % "stanford-corenlp" % StanfordNlpVersion classifier "models-english"
  )

  val tika = Seq(
    "org.apache.tika" % "tika-core" % TikaVersion
  )
  val commonsIO = Seq(
    "commons-io" % "commons-io" % "2.6"
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

  val http4s = Seq(
    "org.http4s" %% "http4s-blaze-server" % Http4sVersion,
    "org.http4s" %% "http4s-circe"        % Http4sVersion,
    "org.http4s" %% "http4s-dsl"          % Http4sVersion,
  )
  
  val http4sClient = Seq(
    "org.http4s" %% "http4s-blaze-client" % Http4sVersion
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

  val fastparse = Seq(
    "com.lihaoyi" %% "fastparse" % FastparseVersion
  )

  // https://github.com/h2database/h2database
  // MPL 2.0 or EPL 1.0
  val h2 = Seq(
    "com.h2database" % "h2" % H2Version
  )
  val mariadb = Seq(
    "org.mariadb.jdbc" % "mariadb-java-client" % MariaDbVersion //flyway doesn't work with newer mariadb
  )
  val postgres = Seq(
    "org.postgresql" % "postgresql" % PostgresVersion
  )
  val sqlite = Seq(
    "org.xerial" % "sqlite-jdbc" % SqliteVersion
  )
  val databases = h2 ++ mariadb ++ postgres ++ sqlite

  // https://github.com/tpolecat/doobie
  // MIT
  val doobie = Seq(
    "org.tpolecat" %% "doobie-core" % DoobieVersion,
    "org.tpolecat" %% "doobie-hikari" % DoobieVersion
  )

  val bitpeace = Seq(
    "com.github.eikek" %% "bitpeace-core" % BitpeaceVersion
  )

  // https://github.com/flyway/flyway
  // ASL 2.0
  val flyway = Seq(
    "org.flywaydb" % "flyway-core" % FlywayVersion
  )

  val yamusca = Seq(
    "com.github.eikek" %% "yamusca-core" % YamuscaVersion
  )

  val miniTest = Seq(
    // https://github.com/monix/minitest
    // Apache 2.0
    "io.monix" %% "minitest" % MiniTestVersion,
    "io.monix" %% "minitest-laws" % MiniTestVersion
  ).map(_ % Test)

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector" % KindProjectorVersion
  val betterMonadicFor = "com.olegpy" %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars" % "swagger-ui" % SwaggerUIVersion,
    "org.webjars" % "Semantic-UI"% SemanticUIVersion,
    "org.webjars" % "jquery" % JQueryVersion,
    "org.webjars" % "viewerjs" % ViewerJSVersion
  )

  val icu4j = Seq(
    "com.ibm.icu" % "icu4j" % Icu4jVersion
  )
}
