package docspell.store

import docspell.common.LenientUri

case class JdbcConfig(url: LenientUri, user: String, password: String) {

  val dbmsName: Option[String] =
    JdbcConfig.extractDbmsName(url)

  def driverClass =
    dbmsName match {
      case Some("mariadb") =>
        "org.mariadb.jdbc.Driver"
      case Some("postgresql") =>
        "org.postgresql.Driver"
      case Some("h2") =>
        "org.h2.Driver"
      case Some("sqlite") =>
        "org.sqlite.JDBC"
      case Some(n) =>
        sys.error(s"Unknown DBMS: $n")
      case None =>
        sys.error("No JDBC url specified")
    }

  override def toString: String =
    s"JdbcConfig($url, $user, ***)"
}

object JdbcConfig {
  def extractDbmsName(jdbcUrl: LenientUri): Option[String] =
    jdbcUrl.scheme.head match {
      case "jdbc" =>
        jdbcUrl.scheme.tail.headOption
      case _ =>
        None
    }
}
