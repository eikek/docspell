/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import scala.concurrent.ExecutionContext

import cats.effect._
import fs2._

import docspell.store.file.FileStore
import docspell.store.impl.StoreImpl

import com.zaxxer.hikari.HikariDataSource
import doobie._
import doobie.hikari.HikariTransactor

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def fileStore: FileStore[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Async](
      jdbc: JdbcConfig,
      chunkSize: Int,
      connectEC: ExecutionContext
  ): Resource[F, Store[F]] = {
    val acquire = Sync[F].delay(new HikariDataSource())
    val free: HikariDataSource => F[Unit] = ds => Sync[F].delay(ds.close())

    for {
      ds <- Resource.make(acquire)(free)
      _ = Resource.pure {
        ds.setJdbcUrl(jdbc.url.asString)
        ds.setUsername(jdbc.user)
        ds.setPassword(jdbc.password)
        ds.setDriverClassName(jdbc.driverClass)
      }
      xa = HikariTransactor(ds, connectEC)
      fs = FileStore[F](xa, ds, chunkSize)
      st = new StoreImpl[F](fs, jdbc, xa)
      _ <- Resource.eval(st.migrate)
    } yield st
  }
}
