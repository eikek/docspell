/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store

import cats.effect._

import docspell.common.LenientUri
import docspell.store.impl.StoreImpl

import doobie._
import munit._
import org.h2.jdbcx.JdbcConnectionPool

trait StoreFixture extends CatsEffectFunFixtures { self: CatsEffectSuite =>

  val xa = ResourceFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      xa <- StoreFixture.makeXA(cfg)
      store = new StoreImpl[IO](cfg, xa)
      _ <- Resource.eval(store.migrate)
    } yield xa
  }

  val store = ResourceFixture {
    val cfg = StoreFixture.memoryDB("test")
    for {
      xa <- StoreFixture.makeXA(cfg)
      store = new StoreImpl[IO](cfg, xa)
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

  def globalXA(jdbc: JdbcConfig): Transactor[IO] =
    Transactor.fromDriverManager(
      "org.h2.Driver",
      jdbc.url.asString,
      jdbc.user,
      jdbc.password
    )

  def makeXA(jdbc: JdbcConfig): Resource[IO, Transactor[IO]] = {
    def jdbcConnPool =
      JdbcConnectionPool.create(jdbc.url.asString, jdbc.user, jdbc.password)

    val makePool = Resource.make(IO(jdbcConnPool))(cp => IO(cp.dispose()))

    for {
      ec   <- ExecutionContexts.cachedThreadPool[IO]
      pool <- makePool
      xa = Transactor.fromDataSource[IO].apply(pool, ec)
    } yield xa
  }

  def store(jdbc: JdbcConfig): Resource[IO, Store[IO]] =
    for {
      xa <- makeXA(jdbc)
      store = new StoreImpl[IO](jdbc, xa)
      _ <- Resource.eval(store.migrate)
    } yield store
}
