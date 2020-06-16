package docspell.joex.process

import cats.implicits._
import cats.effect._
import fs2.Stream
import docspell.common.{ItemState, ProcessItemArgs}
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.queries.QItem
import docspell.store.records.RItem
import docspell.ftsclient.FtsClient

object ItemHandler {
  def onCancel[F[_]: Sync: ContextShift]: Task[F, ProcessItemArgs, Unit] =
    logWarn("Now cancelling. Deleting potentially created data.").flatMap(_ =>
      deleteByFileIds.flatMap(_ => deleteFiles)
    )

  def newItem[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config, fts: FtsClient[F]
  ): Task[F, ProcessItemArgs, Unit] =
    CreateItem[F]
      .flatMap(itemStateTask(ItemState.Processing))
      .flatMap(safeProcess[F](cfg, fts))
      .map(_ => ())

  def itemStateTask[F[_]: Sync, A](
      state: ItemState
  )(data: ItemData): Task[F, A, ItemData] =
    Task(ctx =>
      ctx.store
        .transact(RItem.updateState(data.item.id, state, ItemState.invalidStates))
        .map(_ => data)
    )

  def isLastRetry[F[_]: Sync]: Task[F, ProcessItemArgs, Boolean] =
    Task(_.isLastRetry)

  def safeProcess[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config, fts: FtsClient[F]
  )(data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    isLastRetry[F].flatMap {
      case true =>
        ProcessItem[F](cfg, fts)(data).attempt.flatMap({
          case Right(d) =>
            Task.pure(d)
          case Left(ex) =>
            logWarn[F](
              "Processing failed on last retry. Creating item but without proposals."
            ).flatMap(_ => itemStateTask(ItemState.Created)(data))
              .andThen(_ => Sync[F].raiseError(ex))
        })
      case false =>
        ProcessItem[F](cfg, fts)(data).flatMap(itemStateTask(ItemState.Created))
    }

  def deleteByFileIds[F[_]: Sync: ContextShift]: Task[F, ProcessItemArgs, Unit] =
    Task { ctx =>
      for {
        items <- ctx.store.transact(QItem.findByFileIds(ctx.args.files.map(_.fileMetaId)))
        _     <- ctx.logger.info(s"Deleting items ${items.map(_.id.id)}")
        _     <- items.traverse(i => QItem.delete(ctx.store)(i.id, ctx.args.meta.collective))
      } yield ()
    }

  private def deleteFiles[F[_]: Sync]: Task[F, ProcessItemArgs, Unit] =
    Task(ctx =>
      Stream
        .emits(ctx.args.files.map(_.fileMetaId.id))
        .flatMap(id => ctx.store.bitpeace.delete(id).attempt.drain)
        .compile
        .drain
    )

  private def logWarn[F[_]](msg: => String): Task[F, ProcessItemArgs, Unit] =
    Task(_.logger.warn(msg))
}
