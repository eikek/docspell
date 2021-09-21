/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.migrate

import cats.effect._
import cats.effect.unsafe.implicits._

import docspell.common.LenientUri
import docspell.store.JdbcConfig

import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import munit._
import org.testcontainers.utility.DockerImageName

class PostgresqlMigrateTest extends FunSuite with TestContainerForAll {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:13"))

  test("postgres empty schema migration") {
    assume(Docker.existsUnsafe, "docker doesn't exist!")
    withContainers { cnt =>
      val jdbc =
        JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, cnt.password)
      val result = FlywayMigrate.run[IO](jdbc).unsafeRunSync()
      assert(result.migrationsExecuted > 0)
    }
  }
}
