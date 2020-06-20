package docspell.joex.fts

import cats.effect._
import cats.implicits._
import cats.data.{Kleisli, OptionT}
import cats.Traverse
import docspell.common._
import docspell.joex.Config
import docspell.store.{AddResult, Store}
import docspell.store.records.RFtsMigration
import docspell.store.queries.{QAttachment, QItem}
import docspell.ftsclient._

object Migration {
  private val solrEngine = Ident.unsafe("solr")

  case class MigrateCtx[F[_]](
      cfg: Config.FullTextSearch,
      store: Store[F],
      fts: FtsClient[F],
      logger: Logger[F]
  )

  case class Migration[F[_]](
      version: Int,
      engine: Ident,
      description: String,
      task: Kleisli[F, MigrateCtx[F], Unit]
  )

  def apply[F[_]: Effect](
      cfg: Config.FullTextSearch,
      store: Store[F],
      fts: FtsClient[F],
      logger: Logger[F]
  ): Kleisli[F, List[Migration[F]], Unit] = {
    val ctx = MigrateCtx(cfg, store, fts, logger)
    Kleisli(migs => Traverse[List].sequence(migs.map(applySingle[F](ctx))).map(_ => ()))
  }

  def applySingle[F[_]: Effect](ctx: MigrateCtx[F])(m: Migration[F]): F[Unit] = {
    val insertRecord: F[Option[RFtsMigration]] =
      for {
        rec <- RFtsMigration.create(m.version, m.engine, m.description)
        res <- ctx.store.add(
          RFtsMigration.insert(rec),
          RFtsMigration.exists(m.version, m.engine)
        )
        ret <- res match {
          case AddResult.Success         => rec.some.pure[F]
          case AddResult.EntityExists(_) => None.pure[F]
          case AddResult.Failure(ex)     => Effect[F].raiseError(ex)
        }
      } yield ret

    (for {
      _   <- OptionT.liftF(ctx.logger.info(s"Apply ${m.version}/${m.description}"))
      rec <- OptionT(insertRecord)
      res <- OptionT.liftF(m.task.run(ctx).attempt)
      ret <- OptionT.liftF(res match {
        case Right(()) => ().pure[F]
        case Left(ex) =>
          ctx.logger.error(ex)(
            s"Applying index migration ${m.version}/${m.description} failed"
          ) *>
            ctx.store.transact(RFtsMigration.deleteById(rec.id)) *> Effect[F]
            .raiseError[Unit](
              ex
            )
      })
    } yield ret).getOrElseF(
      ctx.logger.info(s"Migration ${m.version}/${m.description} already applied.")
    )
  }

  def migrationTasks[F[_]: Effect]: List[Migration[F]] =
    List(
      Migration[F](1, solrEngine, "initialize", Kleisli(ctx => ctx.fts.initialize)),
      Migration[F](
        2,
        solrEngine,
        "Index all attachments from database",
        Kleisli(ctx =>
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
        )
      ),
      Migration[F](
        3,
        solrEngine,
        "Index all items from database",
        Kleisli(ctx =>
          ctx.fts.indexData(
            ctx.logger,
            ctx.store
              .transact(QItem.allNameAndNotes(ctx.cfg.migration.indexAllChunk * 5))
              .map(nn => TextData.item(nn.id, nn.collective, Option(nn.name), nn.notes))
          )
        )
      )
    )
}
