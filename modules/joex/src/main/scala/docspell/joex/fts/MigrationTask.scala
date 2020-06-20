package docspell.joex.fts

import cats.effect._
import cats.data.{Kleisli, NonEmptyList}
import cats.{FlatMap, Semigroup}
import docspell.store.queries.{QAttachment, QItem}
import docspell.ftsclient.TextData

object MigrationTask {
  def apply[F[_]](f: MigrateCtx[F] => F[Unit]): MigrationTask[F] =
    Kleisli(f)

  def all[F[_]: FlatMap](
      m0: MigrationTask[F],
      mn: MigrationTask[F]*
  ): MigrationTask[F] =
    NonEmptyList.of(m0, mn: _*).reduce(semigroup[F])

  implicit def semigroup[F[_]: FlatMap]: Semigroup[MigrationTask[F]] =
    Semigroup.instance((mt1, mt2) => mt1.flatMap(_ => mt2))

  // some tasks

  def insertAll[F[_]: Effect]: MigrationTask[F] =
    MigrationTask
      .all(
        MigrationTask(ctx =>
          ctx.fts.indexData(
            ctx.logger,
            ctx.store
              .transact(
                QAttachment.allAttachmentMetaAndName(ctx.cfg.migration.indexAllChunk)
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
        MigrationTask(ctx =>
          ctx.fts.indexData(
            ctx.logger,
            ctx.store
              .transact(QItem.allNameAndNotes(ctx.cfg.migration.indexAllChunk * 5))
              .map(nn => TextData.item(nn.id, nn.collective, Option(nn.name), nn.notes))
          )
        )
      )
}
