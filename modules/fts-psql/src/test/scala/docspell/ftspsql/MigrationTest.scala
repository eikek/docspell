package docspell.ftspsql

import cats.effect._
import docspell.logging.{Level, LogConfig}
import munit.CatsEffectSuite
import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import docspell.common._
import docspell.logging.TestLoggingConfig
import org.testcontainers.utility.DockerImageName
import doobie.implicits._

class MigrationTest
    extends CatsEffectSuite
    with PgFixtures
    with TestContainerForAll
    with TestLoggingConfig {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14"))

  override def docspellLogConfig: LogConfig =
    LogConfig(Level.Debug, LogConfig.Format.Fancy)

  override def rootMinimumLevel = Level.Warn

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
