package docspell.store.migrate

import cats.effect.Sync
import docspell.store.JdbcConfig
import org.flywaydb.core.Flyway
import org.log4s._

object FlywayMigrate {
  private[this] val logger = getLogger

  def run[F[_]: Sync](jdbc: JdbcConfig): F[Int] = Sync[F].delay {
    logger.info("Running db migrations...")
    val locations = jdbc.dbmsName match {
      case Some(dbtype) =>
        val name = if (dbtype == "h2") "postgresql" else dbtype
        List("classpath:db/migration/common", s"classpath:db/migration/${name}")
      case None =>
        logger.warn(s"Cannot read database name from jdbc url: ${jdbc.url}. Go with H2")
        List("classpath:db/migration/common", "classpath:db/h2")
    }

    logger.info(s"Using migration locations: $locations")
    val fw = Flyway.configure().
      cleanDisabled(true).
      dataSource(jdbc.url.asString, jdbc.user, jdbc.password).
      locations(locations: _*).
      load()

    fw.repair()
    fw.migrate()
  }
}
