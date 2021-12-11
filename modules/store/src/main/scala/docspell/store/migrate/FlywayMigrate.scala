/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect.Sync

import docspell.store.JdbcConfig

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult
import org.log4s._

object FlywayMigrate {
  private[this] val logger = getLogger

  def run[F[_]: Sync](jdbc: JdbcConfig): F[MigrateResult] =
    Sync[F].delay {
      logger.info("Running db migrations...")
      val locations = jdbc.dbmsName match {
        case Some(dbtype) =>
          List(s"classpath:db/migration/$dbtype", "classpath:db/migration/common")
        case None =>
          logger.warn(
            s"Cannot read database name from jdbc url: ${jdbc.url}. Go with H2"
          )
          List("classpath:db/migration/h2", "classpath:db/migration/common")
      }

      logger.info(s"Using migration locations: $locations")
      val fw = Flyway
        .configure()
        .cleanDisabled(true)
        .dataSource(jdbc.url.asString, jdbc.user, jdbc.password)
        .locations(locations: _*)
        .load()

      fw.repair()
      fw.migrate()
    }
}
