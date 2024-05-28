/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import java.util.UUID

import cats.effect._
import cats.syntax.option._
import fs2.io.file.{Files, Path}

import docspell.common._
import docspell.logging.TestLoggingConfig

import com.dimafeng.testcontainers.munit.fixtures.TestContainersFixtures
import com.dimafeng.testcontainers.{
  JdbcDatabaseContainer,
  MariaDBContainer,
  PostgreSQLContainer
}
import doobie._
import munit.CatsEffectSuite
import org.testcontainers.utility.DockerImageName

trait DatabaseTest
    extends CatsEffectSuite
    with TestContainersFixtures
    with TestLoggingConfig {

  val cio: Sync[ConnectionIO] = Sync[ConnectionIO]

  lazy val mariadbCnt = ForAllContainerFixture(
    MariaDBContainer.Def(DockerImageName.parse("mariadb:10.5")).createContainer()
  )

  lazy val postgresCnt = ForAllContainerFixture(
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14")).createContainer()
  )

  lazy val pgDataSource = ResourceSuiteLocalFixture(
    "pgDataSource",
    DatabaseTest.makeDataSourceFixture(IO(postgresCnt()))
  )

  lazy val mariaDataSource = ResourceSuiteLocalFixture(
    "mariaDataSource",
    DatabaseTest.makeDataSourceFixture(IO(mariadbCnt()))
  )

  lazy val h2DataSource = ResourceSuiteLocalFixture(
    "h2DataSource", {
      val jdbc = StoreFixture.memoryDB(UUID.randomUUID().toString)
      StoreFixture.dataSource(jdbc).map(ds => (jdbc, ds))
    }
  )

  lazy val h2FileDataSource = ResourceSuiteLocalFixture(
    "h2FileDataSource",
    for {
      file <- Files[IO].tempFile(Path("target").some, "h2-test-", ".db", None)
      jdbc = StoreFixture.fileDB(file)
      res <- StoreFixture.dataSource(jdbc).map(ds => (jdbc, ds))
    } yield res
  )

  lazy val newH2DataSource = ResourceFunFixture(for {
    jdbc <- Resource.eval(IO(StoreFixture.memoryDB(UUID.randomUUID().toString)))
    ds <- StoreFixture.dataSource(jdbc)
  } yield (jdbc, ds))

  lazy val pgStore = ResourceSuiteLocalFixture(
    "pgStore",
    for {
      t <- Resource.eval(IO(pgDataSource()))
      store <- StoreFixture.store(t._2, t._1)
    } yield store
  )

  lazy val mariaStore = ResourceSuiteLocalFixture(
    "mariaStore",
    for {
      t <- Resource.eval(IO(mariaDataSource()))
      store <- StoreFixture.store(t._2, t._1)
    } yield store
  )

  lazy val h2Store = ResourceSuiteLocalFixture(
    "h2Store",
    for {
      t <- Resource.eval(IO(h2DataSource()))
      store <- StoreFixture.store(t._2, t._1)
    } yield store
  )

  lazy val h2FileStore = ResourceSuiteLocalFixture(
    "h2FileStore",
    for {
      t <- Resource.eval(IO(h2FileDataSource()))
      store <- StoreFixture.store(t._2, t._1)
    } yield store
  )

  def postgresAll = List(postgresCnt, pgDataSource, pgStore)
  def mariaDbAll = List(mariadbCnt, mariaDataSource, mariaStore)
  def h2Memory = List(h2DataSource, h2Store)
  def h2File = List(h2FileDataSource, h2FileStore)
}

object DatabaseTest {
  private def jdbcConfig(cnt: JdbcDatabaseContainer) =
    JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, cnt.password)

  private def makeDataSourceFixture(cnt: IO[JdbcDatabaseContainer]) =
    for {
      c <- Resource.eval(cnt)
      jdbc <- Resource.pure(jdbcConfig(c))
      ds <- StoreFixture.dataSource(jdbc)
    } yield (jdbc, ds)
}
