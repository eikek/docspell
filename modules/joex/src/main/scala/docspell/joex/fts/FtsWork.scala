/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.fts

import cats._
import cats.data.{Kleisli, NonEmptyList}
import cats.implicits._

import docspell.backend.fulltext.CreateIndex
import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.scheduler.Context

object FtsWork {
  import syntax._

  def apply[F[_]](f: FtsContext[F] => F[Unit]): FtsWork[F] =
    Kleisli(f)

  /** Runs migration tasks to re-create the index. */
  def reInitializeTasks[F[_]: Monad]: FtsWork[F] =
    FtsWork { ctx =>
      val migrations = ctx.fts.initializeNew
      NonEmptyList.fromList(migrations) match {
        case Some(nel) =>
          nel
            .map(fm =>
              log[F](_.debug(s"Apply (${fm.engine.id}): ${fm.description}")) ++ from[F](
                fm.task
              )
            )
            .reduce(semigroup[F])
            .run(ctx)
        case None =>
          ().pure[F]
      }
    }

  def from[F[_]: FlatMap: Applicative](t: F[FtsMigration.Result]): FtsWork[F] =
    Kleisli.liftF(t).flatMap(transformResult[F])

  def all[F[_]: FlatMap](
      m0: FtsWork[F],
      mn: FtsWork[F]*
  ): FtsWork[F] =
    NonEmptyList.of(m0, mn: _*).reduce(semigroup[F])

  implicit def semigroup[F[_]: FlatMap]: Semigroup[FtsWork[F]] =
    Semigroup.instance((mt1, mt2) => mt1.flatMap(_ => mt2))

  private def transformResult[F[_]: Applicative: FlatMap](
      r: FtsMigration.Result
  ): FtsWork[F] =
    r match {
      case FtsMigration.Result.WorkDone =>
        Kleisli.pure(())

      case FtsMigration.Result.IndexAll =>
        insertAll[F](None)

      case FtsMigration.Result.ReIndexAll =>
        clearIndex[F](None) >> insertAll[F](None)
    }

  // some tasks

  def log[F[_]](f: Logger[F] => F[Unit]): FtsWork[F] =
    FtsWork(ctx => f(ctx.logger))

  def clearIndex[F[_]: FlatMap](coll: Option[Ident]): FtsWork[F] =
    coll match {
      case Some(cid) =>
        log[F](_.debug(s"Clearing index data for collective '${cid.id}'")) ++ FtsWork(
          ctx => ctx.fts.clear(ctx.logger, cid)
        )
      case None =>
        log[F](_.debug("Clearing all index data!")) ++ FtsWork(ctx =>
          ctx.fts.clearAll(ctx.logger)
        )
    }

  def insertAll[F[_]: FlatMap](coll: Option[Ident]): FtsWork[F] =
    log[F](_.info("Inserting all data to index")) ++ FtsWork
      .all(
        FtsWork(ctx =>
          ctx.fulltext
            .reIndexData(ctx.logger, coll, None, ctx.cfg.migration.indexAllChunk)
        )
      )

  object syntax {
    implicit final class FtsWorkOps[F[_]](mt: FtsWork[F]) {
      def ++(mn: FtsWork[F])(implicit ev: FlatMap[F]): FtsWork[F] =
        all(mt, mn)

      def recoverWith(
          other: FtsWork[F]
      )(implicit ev: ApplicativeError[F, Throwable]): FtsWork[F] =
        Kleisli(ctx => mt.run(ctx).onError { case _ => other.run(ctx) })

      def forContext(
          cfg: Config.FullTextSearch,
          fts: FtsClient[F],
          fulltext: CreateIndex[F]
      ): Kleisli[F, Context[F, _], Unit] =
        mt.local(ctx => FtsContext(cfg, fts, fulltext, ctx))
    }
  }
}
