/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import javax.sql.DataSource

import cats.effect._
import fs2.io.file.Path

import docspell.common.LenientUri
import docspell.store.file.{FileRepository, FileRepositoryConfig}
import docspell.store.impl.StoreImpl
import docspell.store.migrate.FlywayMigrate

import doobie._
import munit._
import org.h2.jdbcx.{JdbcConnectionPool, JdbcDataSource}
import org.mariadb.jdbc.MariaDbDataSource
import org.postgresql.ds.PGConnectionPoolDataSource

trait StoreFixture extends CatsEffectFunFixtures { self: CatsEffectSuite =>
  def schemaMigrateConfig =
    StoreFixture.schemaMigrateConfig

  val xa = ResourceFunFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      ds <- StoreFixture.dataSource(cfg)
      xa <- StoreFixture.makeXA(ds)
      _ <- Resource.eval(FlywayMigrate[IO](cfg, schemaMigrateConfig, xa).run)
    } yield xa
  }

  val store = ResourceFunFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      store <- StoreFixture.store(cfg)
      _ <- Resource.eval(store.migrate)
    } yield store
  }
}

object StoreFixture {
  val schemaMigrateConfig = SchemaMigrateConfig.defaults

  def memoryDB(dbname: String): JdbcConfig =
    JdbcConfig(
      LenientUri.unsafe(
        s"jdbc:h2:mem:$dbname;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
      ),
      "sa",
      ""
    )

  def fileDB(file: Path): JdbcConfig =
    JdbcConfig(
      LenientUri.unsafe(
        s"jdbc:h2:file://${file.absolute.toString};MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
      ),
      "sa",
      ""
    )

  def dataSource(jdbc: JdbcConfig): Resource[IO, JdbcConnectionPool] = {
    def jdbcConnPool =
      jdbc.dbms match {
        case Db.MariaDB =>
          val ds = new MariaDbDataSource()
          ds.setUrl(jdbc.url.asString)
          ds.setUser(jdbc.user)
          ds.setPassword(jdbc.password)
          JdbcConnectionPool.create(ds)

        case Db.PostgreSQL =>
          val ds = new PGConnectionPoolDataSource()
          ds.setURL(jdbc.url.asString)
          ds.setUser(jdbc.user)
          ds.setPassword(jdbc.password)
          JdbcConnectionPool.create(ds)

        case Db.H2 =>
          val ds = new JdbcDataSource()
          ds.setURL(jdbc.url.asString)
          ds.setUser(jdbc.user)
          ds.setPassword(jdbc.password)
          JdbcConnectionPool.create(ds)
      }

    Resource.make(IO(jdbcConnPool))(cp => IO(cp.dispose()))
  }

  def makeXA(ds: DataSource): Resource[IO, Transactor[IO]] =
    for {
      ec <- ExecutionContexts.cachedThreadPool[IO]
      xa = Transactor.fromDataSource[IO](ds, ec)
    } yield xa

  def store(jdbc: JdbcConfig): Resource[IO, StoreImpl[IO]] =
    dataSource(jdbc).flatMap(store(_, jdbc))

  def store(ds: DataSource, jdbc: JdbcConfig): Resource[IO, StoreImpl[IO]] =
    for {
      xa <- makeXA(ds)
      cfg = FileRepositoryConfig.Database(64 * 1024)
      fr = FileRepository[IO](xa, ds, cfg, withAttributeStore = true)
      store = new StoreImpl[IO](fr, jdbc, schemaMigrateConfig, ds, xa)
      _ <- Resource.eval(store.migrate)
    } yield store

  def restoreH2Dump(resourceName: String, ds: DataSource): IO[Unit] =
    Option(getClass.getResource(resourceName)).map(_.getFile) match {
      case Some(file) =>
        IO {
          org.log4s.getLogger.info(s"Restoring dump from $file")
          val stmt = ds.getConnection.createStatement()
          val sql = s"RUNSCRIPT FROM '$file'"
          stmt.execute(sql)
          stmt.close()
        }

      case None =>
        IO.raiseError(new Exception(s"Resource not found: $resourceName"))
    }
}
