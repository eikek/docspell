/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.~>
import fs2._

import docspell.store.file.{FileRepository, FileRepositoryConfig}
import docspell.store.impl.StoreImpl

import com.zaxxer.hikari.HikariDataSource
import doobie._
import doobie.hikari.HikariTransactor

trait Store[F[_]] {
  def transform: ConnectionIO ~> F

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def fileRepo: FileRepository[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Async](
      jdbc: JdbcConfig,
      fileRepoConfig: FileRepositoryConfig,
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
      fr = FileRepository.apply(xa, ds, fileRepoConfig)
      st = new StoreImpl[F](fr, jdbc, xa)
      _ <- Resource.eval(st.migrate)
    } yield st
  }
}
