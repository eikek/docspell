/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect.IO
import cats.effect.unsafe.implicits._

import docspell.store.StoreFixture

import munit.FunSuite

class H2MigrateTest extends FunSuite {

  test("h2 empty schema migration") {
    val jdbc   = StoreFixture.memoryDB("h2test")
    val result = FlywayMigrate.run[IO](jdbc).unsafeRunSync()
    assert(result.migrationsExecuted > 0)
  }

}
