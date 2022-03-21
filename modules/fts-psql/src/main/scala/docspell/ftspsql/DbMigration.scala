/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.effect._
import cats.implicits._

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult

final class DbMigration[F[_]: Sync](cfg: PsqlConfig) {
  private[this] val logger = docspell.logging.getLogger[F]
  private val location: String = "classpath:db/psqlfts"

  def run: F[MigrateResult] =
    for {
      fw <- createFlyway
      _ <- logger.info(s"Running FTS migrations")
      result <- Sync[F].blocking(fw.migrate())
    } yield result

  def createFlyway: F[Flyway] =
    for {
      _ <- logger.info(s"Creating Flyway for: $location")
      fw = Flyway
        .configure()
        .table("flyway_fts_history")
        .cleanDisabled(true)
        .dataSource(cfg.url.asString, cfg.user, cfg.password.pass)
        .locations(location)
        .baselineOnMigrate(true)
        .load()
    } yield fw
}

object DbMigration {
  def apply[F[_]: Sync](cfg: PsqlConfig): DbMigration[F] =
    new DbMigration[F](cfg)
}
