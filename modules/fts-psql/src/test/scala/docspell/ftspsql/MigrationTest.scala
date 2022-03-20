package docspell.ftspsql

import cats.effect._
import cats.effect.unsafe.implicits._
import docspell.logging.{Level, LogConfig}
//import cats.implicits._
import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import docspell.common._
import docspell.logging.TestLoggingConfig
import munit.FunSuite
import org.testcontainers.utility.DockerImageName

class MigrationTest extends FunSuite with TestContainerForAll with TestLoggingConfig {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14"))

  override def docspellLogConfig: LogConfig =
    LogConfig(Level.Debug, LogConfig.Format.Fancy)

  override def rootMinimumLevel = Level.Warn

  test("create schema") {
    withContainers { cnt =>
      val jdbc =
        PsqlConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, Password(cnt.password))

      new DbMigration[IO](jdbc).run.void.unsafeRunSync()
    }
  }
}
