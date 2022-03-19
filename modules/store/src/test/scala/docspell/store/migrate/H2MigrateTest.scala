/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect.IO
import cats.effect.unsafe.implicits._

import docspell.logging.TestLoggingConfig
import docspell.store.StoreFixture

import munit.FunSuite

class H2MigrateTest extends FunSuite with TestLoggingConfig {

  test("h2 empty schema migration") {
    val jdbc = StoreFixture.memoryDB("h2test")
    val ds = StoreFixture.dataSource(jdbc)
    val result =
      ds.flatMap(StoreFixture.makeXA).use { xa =>
        FlywayMigrate[IO](jdbc, xa).run
      }

    assert(result.unsafeRunSync().migrationsExecuted > 0)

    // a second time to apply fixup migrations
    assert(result.unsafeRunSync().migrationsExecuted == 0)
  }
}
