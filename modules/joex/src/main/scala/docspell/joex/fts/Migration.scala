/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.fts

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import cats.{Applicative, FlatMap, Traverse}

import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.store.Store

/** Migrating the index from the previous version to this version.
  *
  * The migration asks the fulltext search client for a list of
  * migration tasks to run. It may be empty when there is no migration
  * required.
  */
case class Migration[F[_]](
    version: Int,
    engine: Ident,
    description: String,
    task: FtsWork[F]
)

object Migration {

  def from[F[_]: Applicative: FlatMap](fm: FtsMigration[F]): Migration[F] =
    Migration(fm.version, fm.engine, fm.description, FtsWork.from(fm.task))

  def apply[F[_]: Async](
      cfg: Config.FullTextSearch,
      fts: FtsClient[F],
      store: Store[F],
      logger: Logger[F]
  ): Kleisli[F, List[Migration[F]], Unit] = {
    val ctx = FtsContext(cfg, store, fts, logger)
    Kleisli { migs =>
      if (migs.isEmpty) logger.info("No fulltext search migrations to run.")
      else Traverse[List].sequence(migs.map(applySingle[F](ctx))).map(_ => ())
    }
  }

  def applySingle[F[_]: Async](ctx: FtsContext[F])(m: Migration[F]): F[Unit] =
    for {
      _ <- ctx.logger.info(s"Apply ${m.version}/${m.description}")
      _ <- m.task.run(ctx)
    } yield ()
}
