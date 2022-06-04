/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.effect._

import docspell.common._
import docspell.logging.TestLoggingConfig
import docspell.logging.{Level, LogConfig}

import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import doobie.implicits._
import munit.CatsEffectSuite
import org.testcontainers.utility.DockerImageName

class MigrationTest
    extends CatsEffectSuite
    with PgFixtures
    with TestContainerForAll
    with TestLoggingConfig {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14"))

  override def docspellLogConfig: LogConfig =
    super.docspellLogConfig.docspellLevel(Level.Error)

  test("create schema") {
    withContainers { cnt =>
      val jdbc =
        PsqlConfig.defaults(
          LenientUri.unsafe(cnt.jdbcUrl),
          cnt.username,
          Password(cnt.password)
        )

      for {
        _ <- DbMigration[IO](jdbc).run
        n <- runQuery(cnt)(
          sql"SELECT count(*) FROM ${FtsRepository.table}".query[Int].unique
        )
        _ = assertEquals(n, 0)
      } yield ()
    }
  }
}
