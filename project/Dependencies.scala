package docspell.build

import sbt._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BitpeaceVersion = "0.4.3"
  val CirceVersion = "0.12.3"
  val DoobieVersion = "0.8.8"
  val EmilVersion = "0.2.0"
  val FastparseVersion = "2.1.3"
  val FlywayVersion = "6.2.0"
  val Fs2Version = "2.1.0"
  val H2Version = "1.4.200"
  val Http4sVersion = "0.21.0-RC2"
  val KindProjectorVersion = "0.10.3"
  val Log4sVersion = "1.8.2"
  val LogbackVersion = "1.2.3"
  val MariaDbVersion = "2.5.4"
  val MiniTestVersion = "2.7.0"
  val PostgresVersion = "42.2.9"
  val PureConfigVersion = "0.12.2"
  val SqliteVersion = "3.30.1"
  val StanfordNlpVersion = "3.9.2"
  val TikaVersion = "1.23"
  val YamuscaVersion = "0.6.1"

  val emil = Seq(
    "com.github.eikek" %% "emil-common" % EmilVersion,
    "com.github.eikek" %% "emil-javamail" % EmilVersion    
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
    "swagger-ui" -> "3.24.3",
    "Semantic-UI" -> "2.4.1",
    "jquery" -> "3.4.1"
  ).map({case (a, v) => "org.webjars" % a % v })

}
