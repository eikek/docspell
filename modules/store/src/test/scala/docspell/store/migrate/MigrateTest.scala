/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect._
import docspell.store.{DatabaseTest, SchemaMigrateConfig, StoreFixture}
import org.flywaydb.core.api.output.MigrateResult

class MigrateTest extends DatabaseTest {

  // don't register store-Fixture as this would run the migrations already
  override def munitFixtures =
    List(postgresCnt, mariadbCnt, pgDataSource, mariaDataSource, h2DataSource)

  test("postgres empty schema migration") {
    val (jdbc, ds) = pgDataSource()
    val result =
      StoreFixture.makeXA(ds).use { xa =>
        FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
      }

    assertMigrationResult(result)
  }

  test("mariadb empty schema migration") {
    val (jdbc, ds) = mariaDataSource()
    val result =
      StoreFixture.makeXA(ds).use { xa =>
        FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
      }

    assertMigrationResult(result)
  }

  test("h2 empty schema migration") {
    val (jdbc, ds) = h2DataSource()
    val result =
      StoreFixture.makeXA(ds).use { xa =>
        FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
      }

    assertMigrationResult(result)
  }

  newH2DataSource.test("h2 upgrade db from 0.24.0") { case (jdbc, ds) =>
    val dump = "/docspell-0.24.0-dump-h2-1.24.0-2021-07-13-2307.sql"
    for {
      _ <- StoreFixture.restoreH2Dump(dump, ds)

      result =
        StoreFixture.makeXA(ds).use { xa =>
          FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
        }

      _ <- result
      _ <- result
    } yield ()
  }

  def assertMigrationResult(migrate: IO[MigrateResult]) =
    for {
      r1 <- migrate.map(_.migrationsExecuted)
      // a second time to apply fixup migrations
      r2 <- migrate.map(_.migrationsExecuted)
    } yield {
      assert(r1 > 0)
      assertEquals(r2, 0)
    }
}
