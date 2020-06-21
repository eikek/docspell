package docspell.joex.fts

import cats.effect._
import cats.data.{Kleisli, NonEmptyList}
import cats.{FlatMap, Semigroup}
import docspell.common._
import docspell.ftsclient._
import docspell.joex.scheduler.Context
import docspell.joex.Config
import docspell.store.queries.{QAttachment, QItem}

object FtsWork {
  def apply[F[_]](f: FtsContext[F] => F[Unit]): FtsWork[F] =
    Kleisli(f)

  def all[F[_]: FlatMap](
      m0: FtsWork[F],
      mn: FtsWork[F]*
  ): FtsWork[F] =
    NonEmptyList.of(m0, mn: _*).reduce(semigroup[F])

  implicit def semigroup[F[_]: FlatMap]: Semigroup[FtsWork[F]] =
    Semigroup.instance((mt1, mt2) => mt1.flatMap(_ => mt2))

  // some tasks

  def initialize[F[_]]: FtsWork[F] =
    FtsWork(_.fts.initialize)

  def clearIndex[F[_]](coll: Option[Ident]): FtsWork[F] =
    coll match {
      case Some(cid) =>
        FtsWork(ctx => ctx.fts.clear(ctx.logger, cid))
      case None =>
        FtsWork(ctx => ctx.fts.clearAll(ctx.logger))
    }

  def insertAll[F[_]: Effect](coll: Option[Ident]): FtsWork[F] =
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
              .map(nn => TextData.item(nn.id, nn.collective, Option(nn.name), nn.notes))
          )
        )
      )

  object syntax {
    implicit final class FtsWorkOps[F[_]](mt: FtsWork[F]) {
      def ++(mn: FtsWork[F])(implicit ev: FlatMap[F]): FtsWork[F] =
        all(mt, mn)

      def forContext(
          cfg: Config.FullTextSearch,
          fts: FtsClient[F]
      ): Kleisli[F, Context[F, _], Unit] =
        mt.local(ctx => FtsContext(cfg, fts, ctx))
    }
  }
}
