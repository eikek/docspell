import sbt._

object Dependencies {

  val BetterMonadicForVersion = "0.3.0"
  val BitpeaceVersion = "0.4.0-M2"
  val CirceVersion = "0.12.0-M4"
  val DoobieVersion = "0.8.0-M1"
  val FastparseVersion = "2.1.3"
  val FlywayVersion = "6.0.0-beta2"
  val Fs2Version = "1.1.0-M1"
  val H2Version = "1.4.199"
  val Http4sVersion = "0.21.0-M2"
  val KindProjectorVersion = "0.10.3"
  val Log4sVersion = "1.8.2"
  val LogbackVersion = "1.2.3"
  val MariaDbVersion = "2.4.2"
  val MiniTestVersion = "2.5.0"
  val PostgresVersion = "42.2.6"
  val PureConfigVersion = "0.11.1"
  val SqliteVersion = "3.28.0"
  val TikaVersion = "1.20"
  val javaxMailVersion = "1.6.2"
  val dnsJavaVersion = "2.1.9"
  val YamuscaVersion = "0.6.0-M2"


  val fs2 = Seq(
    "co.fs2" %% "fs2-core" % Fs2Version
  )

  val http4s = Seq(
    "org.http4s" %% "http4s-blaze-server" % Http4sVersion,
    "org.http4s" %% "http4s-circe"        % Http4sVersion,
    "org.http4s" %% "http4s-dsl"          % Http4sVersion,
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
    "ch.qos.logback" % "logback-classic" % LogbackVersion % Runtime
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

  val javaxMail = Seq(
    "javax.mail" % "javax.mail-api" % javaxMailVersion,
    "com.sun.mail" % "javax.mail" % javaxMailVersion,
    "dnsjava" % "dnsjava" % dnsJavaVersion intransitive()
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
    "swagger-ui" -> "3.22.2",
    "Semantic-UI" -> "2.4.1",
    "jquery" -> "3.4.1"
  ).map({case (a, v) => "org.webjars" % a % v })

}
