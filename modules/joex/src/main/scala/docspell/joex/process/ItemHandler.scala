package docspell.joex.process

import cats.implicits._
import cats.effect._
import docspell.common.{ItemState, ProcessItemArgs}
import docspell.joex.Config
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QItem
import docspell.store.records.{RItem, RJob}

object ItemHandler {
  def onCancel[F[_]: Sync: ContextShift]: Task[F, ProcessItemArgs, Unit] =
    logWarn("Now cancelling. Deleting potentially created data.").flatMap(_ => deleteByFileIds)

  def apply[F[_]: ConcurrentEffect: ContextShift](cfg: Config): Task[F, ProcessItemArgs, Unit] =
    CreateItem[F]
      .flatMap(itemStateTask(ItemState.Processing))
      .flatMap(safeProcess[F](cfg))
      .map(_ => ())

  def itemStateTask[F[_]: Sync, A](state: ItemState)(data: ItemData): Task[F, A, ItemData] =
    Task(ctx => ctx.store.transact(RItem.updateState(data.item.id, state)).map(_ => data))

  def isLastRetry[F[_]: Sync, A](ctx: Context[F, A]): F[Boolean] =
    for {
      current <- ctx.store.transact(RJob.getRetries(ctx.jobId))
      last = ctx.config.retries == current.getOrElse(0)
    } yield last

  def safeProcess[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config
  )(data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task(isLastRetry[F, ProcessItemArgs] _).flatMap {
      case true =>
        ProcessItem[F](cfg)(data).attempt.flatMap({
          case Right(d) =>
            Task.pure(d)
          case Left(ex) =>
            logWarn[F]("Processing failed on last retry. Creating item but without proposals.")
              .flatMap(_ => itemStateTask(ItemState.Created)(data))
              .andThen(_ => Sync[F].raiseError(ex))
        })
      case false =>
        ProcessItem[F](cfg)(data).flatMap(itemStateTask(ItemState.Created))
    }

  def deleteByFileIds[F[_]: Sync: ContextShift]: Task[F, ProcessItemArgs, Unit] =
    Task { ctx =>
      for {
        items <- ctx.store.transact(QItem.findByFileIds(ctx.args.files.map(_.fileMetaId)))
        _     <- ctx.logger.info(s"Deleting items ${items.map(_.id.id)}")
        _     <- items.traverse(i => QItem.delete(ctx.store)(i.id, ctx.args.meta.collective))
      } yield ()
    }

  private def logWarn[F[_]](msg: => String): Task[F, ProcessItemArgs, Unit] =
    Task(_.logger.warn(msg))
}
