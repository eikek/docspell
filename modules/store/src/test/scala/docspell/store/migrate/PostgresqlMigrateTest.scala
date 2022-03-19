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
import docspell.store.{JdbcConfig, StoreFixture}

import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import munit._
import org.testcontainers.utility.DockerImageName

class PostgresqlMigrateTest
    extends FunSuite
    with TestContainerForAll
    with TestLoggingConfig {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:13"))

  test("postgres empty schema migration") {
    assume(Docker.existsUnsafe, "docker doesn't exist!")
    withContainers { cnt =>
      val jdbc =
        JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, cnt.password)

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
}
