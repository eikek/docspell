package docspell.store

import cats.effect._
import com.dimafeng.testcontainers.{
  JdbcDatabaseContainer,
  MariaDBContainer,
  PostgreSQLContainer
}
import com.dimafeng.testcontainers.munit.fixtures.TestContainersFixtures
import docspell.common._
import docspell.logging.TestLoggingConfig
import munit.CatsEffectSuite
import org.testcontainers.utility.DockerImageName

import java.util.UUID

trait DatabaseTest
    extends CatsEffectSuite
    with TestContainersFixtures
    with TestLoggingConfig {

  lazy val mariadbCnt = ForAllContainerFixture(
    MariaDBContainer.Def(DockerImageName.parse("mariadb:10.5")).createContainer()
  )

  lazy val postgresCnt = ForAllContainerFixture(
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14")).createContainer()
  )

  lazy val pgDataSource = ResourceSuiteLocalFixture(
    "pgDataSource",
    DatabaseTest.makeDataSourceFixture(postgresCnt())
  )

  lazy val mariaDataSource = ResourceSuiteLocalFixture(
    "mariaDataSource",
    DatabaseTest.makeDataSourceFixture(mariadbCnt())
  )

  lazy val h2DataSource = ResourceSuiteLocalFixture(
    "h2DataSource", {
      val jdbc = StoreFixture.memoryDB("test")
      StoreFixture.dataSource(jdbc).map(ds => (jdbc, ds))
    }
  )

  lazy val newH2DataSource = ResourceFixture(for {
    jdbc <- Resource.eval(IO(StoreFixture.memoryDB(UUID.randomUUID().toString)))
    ds <- StoreFixture.dataSource(jdbc)
  } yield (jdbc, ds))

  lazy val pgStore = ResourceSuiteLocalFixture(
    "pgStore", {
      val (jdbc, ds) = pgDataSource()
      StoreFixture.store(ds, jdbc)
    }
  )

  lazy val mariaStore = ResourceSuiteLocalFixture(
    "mariaStore", {
      val (jdbc, ds) = mariaDataSource()
      StoreFixture.store(ds, jdbc)
    }
  )

  lazy val h2Store = ResourceSuiteLocalFixture(
    "h2Store", {
      val (jdbc, ds) = h2DataSource()
      StoreFixture.store(ds, jdbc)
    }
  )
}

object DatabaseTest {
  private def jdbcConfig(cnt: JdbcDatabaseContainer) =
    JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, cnt.password)

  private def makeDataSourceFixture(cnt: JdbcDatabaseContainer) =
    for {
      jdbc <- Resource.eval(IO(jdbcConfig(cnt)))
      ds <- StoreFixture.dataSource(jdbc)
    } yield (jdbc, ds)
}
