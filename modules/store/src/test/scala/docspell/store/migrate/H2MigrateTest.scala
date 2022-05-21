/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect.IO
import cats.effect.unsafe.implicits._

import docspell.logging.TestLoggingConfig
import docspell.store.{SchemaMigrateConfig, StoreFixture}

import munit.FunSuite

class H2MigrateTest extends FunSuite with TestLoggingConfig {

  test("h2 empty schema migration") {
    val jdbc = StoreFixture.memoryDB("h2test")
    val ds = StoreFixture.dataSource(jdbc)
    val result =
      ds.flatMap(StoreFixture.makeXA).use { xa =>
        FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
      }

    assert(result.unsafeRunSync().migrationsExecuted > 0)

    // a second time to apply fixup migrations
    assert(result.unsafeRunSync().migrationsExecuted == 0)
  }

  test("h2 upgrade db from 0.24.0") {
    val dump = "/docspell-0.24.0-dump-h2-1.24.0-2021-07-13-2307.sql"

    val jdbc = StoreFixture.memoryDB("h2test2")
    val ds = StoreFixture.dataSource(jdbc)

    ds.use(StoreFixture.restoreH2Dump(dump, _)).unsafeRunSync()

    val result =
      ds.flatMap(StoreFixture.makeXA).use { xa =>
        FlywayMigrate[IO](jdbc, SchemaMigrateConfig.defaults, xa).run
      }

    result.unsafeRunSync()
    result.unsafeRunSync()
  }
}
