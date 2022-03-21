/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.impl

import javax.sql.DataSource

import cats.arrow.FunctionK
import cats.effect.Async
import cats.implicits._
import cats.~>

import docspell.store.file.{FileRepository, FileRepositoryConfig}
import docspell.store.migrate.FlywayMigrate
import docspell.store.{AddResult, JdbcConfig, Store}

import doobie._
import doobie.implicits._

final class StoreImpl[F[_]: Async](
    val fileRepo: FileRepository[F],
    jdbc: JdbcConfig,
    ds: DataSource,
    val transactor: Transactor[F]
) extends Store[F] {
  private[this] val xa = transactor

  def createFileRepository(
      cfg: FileRepositoryConfig,
      withAttributeStore: Boolean
  ): FileRepository[F] =
    FileRepository(xa, ds, cfg, withAttributeStore)

  def transform: ConnectionIO ~> F =
    FunctionK.lift(transact)

  def migrate: F[Int] =
    FlywayMigrate[F](jdbc, xa).run.map(_.migrationsExecuted)

  def transact[A](prg: ConnectionIO[A]): F[A] =
    prg.transact(xa)

  def transact[A](prg: fs2.Stream[ConnectionIO, A]): fs2.Stream[F, A] =
    prg.transact(xa)

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult] =
    for {
      save <- transact(insert).attempt
      exist <- save.swap.traverse(ex => transact(exists).map(b => (ex, b)))
    } yield exist.swap match {
      case Right(_) => AddResult.Success
      case Left((_, true)) =>
        AddResult.EntityExists("Adding failed, because the entity already exists.")
      case Left((ex, _)) => AddResult.Failure(ex)
    }
}
