/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import scala.concurrent.ExecutionContext

import cats.effect._
import fs2._

import docspell.store.impl.StoreImpl

import bitpeace.Bitpeace
import doobie._
import doobie.hikari.HikariTransactor

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def bitpeace: Bitpeace[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Async](
      jdbc: JdbcConfig,
      connectEC: ExecutionContext
  ): Resource[F, Store[F]] = {

    val hxa = HikariTransactor.newHikariTransactor[F](
      jdbc.driverClass,
      jdbc.url.asString,
      jdbc.user,
      jdbc.password,
      connectEC
    )

    for {
      xa <- hxa
      st = new StoreImpl[F](jdbc, xa)
      _ <- Resource.eval(st.migrate)
    } yield st
  }
}
