/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect.Sync
import cats.implicits._

import docspell.store.JdbcConfig
import docspell.store.migrate.FlywayMigrate.MigrationKind

import doobie.implicits._
import doobie.util.transactor.Transactor
import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult

class FlywayMigrate[F[_]: Sync](jdbc: JdbcConfig, xa: Transactor[F]) {
  private[this] val logger = docspell.logging.getLogger[F]

  private def createLocations(folder: String) =
    jdbc.dbmsName match {
      case Some(dbtype) =>
        List(s"classpath:db/$folder/$dbtype", s"classpath:db/$folder/common")
      case None =>
        logger.warn(
          s"Cannot read database name from jdbc url: ${jdbc.url}. Go with H2"
        )
        List(s"classpath:db/$folder/h2", s"classpath:db/$folder/common")
    }

  def createFlyway(kind: MigrationKind): F[Flyway] =
    for {
      locations <- Sync[F].pure(createLocations(kind.folder))
      _ <- logger.info(s"Creating Flyway for: $locations")
      fw = Flyway
        .configure()
        .table(kind.table)
        .cleanDisabled(true)
        .dataSource(jdbc.url.asString, jdbc.user, jdbc.password)
        .locations(locations: _*)
        .baselineOnMigrate(kind == MigrationKind.Fixups)
        .load()
    } yield fw

  def run: F[MigrateResult] =
    for {
      _ <- runFixups
      fw <- createFlyway(MigrationKind.Main)
      _ <- logger.info(s"!!! Running main migrations")
      result <- Sync[F].blocking(fw.migrate())
    } yield result

  // A hack to fix already published migrations
  def runFixups: F[Unit] =
    isSchemaEmpty.flatMap {
      case true =>
        ().pure[F]
      case false =>
        for {
          fw <- createFlyway(MigrationKind.Fixups)
          _ <- logger.info(s"!!! Running fixup migrations")
          _ <- Sync[F].blocking(fw.migrate())
        } yield ()
    }

  private def isSchemaEmpty: F[Boolean] =
    sql"select count(1) from flyway_schema_history"
      .query[Int]
      .unique
      .attemptSql
      .transact(xa)
      .map(_.isLeft)
}

object FlywayMigrate {
  def apply[F[_]: Sync](jdbcConfig: JdbcConfig, xa: Transactor[F]): FlywayMigrate[F] =
    new FlywayMigrate[F](jdbcConfig, xa)

  sealed trait MigrationKind {
    def table: String
    def folder: String
  }
  object MigrationKind {
    case object Main extends MigrationKind {
      val table = "flyway_schema_history"
      val folder = "migration"
    }
    case object Fixups extends MigrationKind {
      val table = "flyway_fixup_history"
      val folder = "fixups"
    }
  }
}
