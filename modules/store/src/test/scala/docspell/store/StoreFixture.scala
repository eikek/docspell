/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import javax.sql.DataSource

import cats.effect._

import docspell.common.LenientUri
import docspell.store.file.{FileRepository, FileRepositoryConfig}
import docspell.store.impl.StoreImpl
import docspell.store.migrate.FlywayMigrate

import doobie._
import munit._
import org.h2.jdbcx.JdbcConnectionPool

trait StoreFixture extends CatsEffectFunFixtures { self: CatsEffectSuite =>

  val xa = ResourceFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      ds <- StoreFixture.dataSource(cfg)
      xa <- StoreFixture.makeXA(ds)
      _ <- Resource.eval(FlywayMigrate.run[IO](cfg))
    } yield xa
  }

  val store = ResourceFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      store <- StoreFixture.store(cfg)
      _ <- Resource.eval(store.migrate)
    } yield store
  }
}

object StoreFixture {

  def memoryDB(dbname: String): JdbcConfig =
    JdbcConfig(
      LenientUri.unsafe(
        s"jdbc:h2:mem:$dbname;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
      ),
      "sa",
      ""
    )

  def dataSource(jdbc: JdbcConfig): Resource[IO, JdbcConnectionPool] = {
    def jdbcConnPool =
      JdbcConnectionPool.create(jdbc.url.asString, jdbc.user, jdbc.password)

    Resource.make(IO(jdbcConnPool))(cp => IO(cp.dispose()))
  }

  def makeXA(ds: DataSource): Resource[IO, Transactor[IO]] =
    for {
      ec <- ExecutionContexts.cachedThreadPool[IO]
      xa = Transactor.fromDataSource[IO](ds, ec)
    } yield xa

  def store(jdbc: JdbcConfig): Resource[IO, StoreImpl[IO]] =
    for {
      ds <- dataSource(jdbc)
      xa <- makeXA(ds)
      cfg = FileRepositoryConfig.Database(64 * 1024)
      fr = FileRepository[IO](xa, ds, cfg)
      store = new StoreImpl[IO](fr, jdbc, ds, xa)
      _ <- Resource.eval(store.migrate)
    } yield store
}
