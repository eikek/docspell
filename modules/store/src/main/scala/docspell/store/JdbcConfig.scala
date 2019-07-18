package docspell.store

case class JdbcConfig(url: String
  , user: String
  , password: String
) {

  def driverClass =
    JdbcConfig.extractDbmsName(url) match {
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

}

object JdbcConfig {
  private[this] val jdbcRegex = "jdbc\\:([^\\:]+)\\:.*".r
  def extractDbmsName(jdbcUrl: String): Option[String] =
    jdbcUrl match {
      case jdbcRegex(n) => Some(n)
      case _ => None
    }
}
