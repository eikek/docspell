/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect._
import cats.effect.unsafe.implicits._

import docspell.common.LenientUri
import docspell.logging.TestLoggingConfig
import docspell.store.JdbcConfig

import com.dimafeng.testcontainers.MariaDBContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import munit._
import org.testcontainers.utility.DockerImageName

class MariaDbMigrateTest
    extends FunSuite
    with TestContainerForAll
    with TestLoggingConfig {
  override val containerDef: MariaDBContainer.Def =
    MariaDBContainer.Def(DockerImageName.parse("mariadb:10.5"))

  test("mariadb empty schema migration") {
    assume(Docker.existsUnsafe, "docker doesn't exist!")
    withContainers { cnt =>
      val jdbc =
        JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.dbUsername, cnt.dbPassword)
      val result = FlywayMigrate.run[IO](jdbc).unsafeRunSync()
      assert(result.migrationsExecuted > 0)
    }
  }
}
