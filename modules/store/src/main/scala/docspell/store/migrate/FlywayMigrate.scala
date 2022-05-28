/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._

import docspell.store.migrate.FlywayMigrate.MigrationKind
import docspell.store.{JdbcConfig, SchemaMigrateConfig}

import doobie.implicits._
import doobie.util.transactor.Transactor
import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult

class FlywayMigrate[F[_]: Sync](
    jdbc: JdbcConfig,
    cfg: SchemaMigrateConfig,
    xa: Transactor[F]
) {
  private[this] val logger = docspell.logging.getLogger[F]

  private def createLocations(folder: String) =
    List(s"classpath:db/$folder/${jdbc.dbms.name}", s"classpath:db/$folder/common")

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
      result <- runMain
    } yield result

  def runMain: F[MigrateResult] =
    if (!cfg.runMainMigrations)
      logger
        .info("Running main migrations is disabled!")
        .as(new MigrateResult("", "", ""))
    else
      for {
        fw <- createFlyway(MigrationKind.Main)
        _ <- logger.info(s"!!! Running main migrations (repair=${cfg.repairSchema})")
        _ <- if (cfg.repairSchema) Sync[F].blocking(fw.repair()).void else ().pure[F]
        result <- Sync[F].blocking(fw.migrate())
      } yield result

  // A hack to fix already published migrations
  def runFixups: F[Unit] =
    if (!cfg.runFixupMigrations) logger.info(s"Running fixup migrations is disabled!")
    else
      isSchemaEmpty.flatMap {
        case true =>
          ().pure[F]
        case false =>
          (for {
            current <- OptionT(getSchemaVersion)
            _ <- OptionT
              .fromOption[F](versionComponents(current))
              .filter(v => v._1 >= 1 && v._2 >= 32)
            fw <- OptionT.liftF(createFlyway(MigrationKind.Fixups))
            _ <- OptionT.liftF(
              logger.info(s"!!! Running fixup migrations (repair=${cfg.repairSchema})")
            )
            _ <-
              if (cfg.repairSchema) OptionT.liftF(Sync[F].blocking(fw.repair()).void)
              else OptionT.pure[F](())
            _ <- OptionT.liftF(Sync[F].blocking(fw.migrate()))
          } yield ())
            .getOrElseF(logger.info(s"Fixup migrations not applied."))
      }

  private def isSchemaEmpty: F[Boolean] =
    sql"select count(1) from flyway_schema_history"
      .query[Int]
      .unique
      .attemptSql
      .transact(xa)
      .map(_.isLeft)

  private def getSchemaVersion: F[Option[String]] =
    sql"select version from flyway_schema_history where success = true order by installed_rank desc limit 1"
      .query[String]
      .option
      .transact(xa)

  private def versionComponents(v: String): Option[(Int, Int, Int)] =
    v.split('.').toList.map(_.toIntOption) match {
      case Some(a) :: Some(b) :: Some(c) :: Nil =>
        Some((a, b, c))
      case _ => None
    }
}

object FlywayMigrate {
  def apply[F[_]: Sync](
      jdbcConfig: JdbcConfig,
      schemaCfg: SchemaMigrateConfig,
      xa: Transactor[F]
  ): FlywayMigrate[F] =
    new FlywayMigrate[F](jdbcConfig, schemaCfg, xa)

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
