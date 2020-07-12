package docspell.joex.fts

import cats.data.{Kleisli, NonEmptyList}
import cats.implicits._
import cats.{Applicative, ApplicativeError, FlatMap, Monad, Semigroup}

import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.scheduler.Context
import docspell.store.queries.{QAttachment, QItem}

object FtsWork {
  def apply[F[_]](f: FtsContext[F] => F[Unit]): FtsWork[F] =
    Kleisli(f)

  def allInitializeTasks[F[_]: Monad]: FtsWork[F] =
    FtsWork[F](_ => ().pure[F]).tap[FtsContext[F]].flatMap { ctx =>
      NonEmptyList.fromList(ctx.fts.initialize.map(fm => from[F](fm.task))) match {
        case Some(nel) =>
          nel.reduce(semigroup[F])
        case None =>
          FtsWork[F](_ => ().pure[F])
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

  def clearIndex[F[_]](coll: Option[Ident]): FtsWork[F] =
    coll match {
      case Some(cid) =>
        FtsWork(ctx => ctx.fts.clear(ctx.logger, cid))
      case None =>
        FtsWork(ctx => ctx.fts.clearAll(ctx.logger))
    }

  def insertAll[F[_]: FlatMap](coll: Option[Ident]): FtsWork[F] =
    FtsWork
      .all(
        FtsWork(ctx =>
          ctx.fts.indexData(
            ctx.logger,
            ctx.store
              .transact(
                QAttachment
                  .allAttachmentMetaAndName(coll, ctx.cfg.migration.indexAllChunk)
              )
              .map(caa =>
                TextData
                  .attachment(
                    caa.item,
                    caa.id,
                    caa.collective,
                    caa.folder,
                    caa.lang,
                    caa.name,
                    caa.content
                  )
              )
          )
        ),
        FtsWork(ctx =>
          ctx.fts.indexData(
            ctx.logger,
            ctx.store
              .transact(QItem.allNameAndNotes(coll, ctx.cfg.migration.indexAllChunk * 5))
              .map(nn =>
                TextData.item(nn.id, nn.collective, nn.folder, Option(nn.name), nn.notes)
              )
          )
        )
      )

  object syntax {
    implicit final class FtsWorkOps[F[_]](mt: FtsWork[F]) {
      def ++(mn: FtsWork[F])(implicit ev: FlatMap[F]): FtsWork[F] =
        all(mt, mn)

      def recoverWith(
          other: FtsWork[F]
      )(implicit ev: ApplicativeError[F, Throwable]): FtsWork[F] =
        Kleisli(ctx => mt.run(ctx).onError({ case _ => other.run(ctx) }))

      def forContext(
          cfg: Config.FullTextSearch,
          fts: FtsClient[F]
      ): Kleisli[F, Context[F, _], Unit] =
        mt.local(ctx => FtsContext(cfg, fts, ctx))
    }
  }
}
