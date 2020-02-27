package docspell.joex

import cats.implicits._
import cats.effect._
import docspell.common.{Ident, NodeType, ProcessItemArgs}
import docspell.joex.process.ItemHandler
import docspell.joex.scheduler.{JobTask, Scheduler, SchedulerBuilder}
import docspell.store.Store
import docspell.store.ops.ONode
import docspell.store.records.RJobLog
import fs2.concurrent.SignallingRef

import scala.concurrent.ExecutionContext

final class JoexAppImpl[F[_]: ConcurrentEffect: ContextShift: Timer](
    cfg: Config,
    nodeOps: ONode[F],
    store: Store[F],
    termSignal: SignallingRef[F, Boolean],
    val scheduler: Scheduler[F]
) extends JoexApp[F] {

  def init: F[Unit] = {
    val run = scheduler.start.compile.drain
    for {
      _ <- ConcurrentEffect[F].start(run)
      _ <- scheduler.periodicAwake
      _ <- nodeOps.register(cfg.appId, NodeType.Joex, cfg.baseUrl)
    } yield ()
  }

  def findLogs(jobId: Ident): F[Vector[RJobLog]] =
    store.transact(RJobLog.findLogs(jobId))

  def shutdown: F[Unit] =
    nodeOps.unregister(cfg.appId)

  def initShutdown: F[Unit] =
    scheduler.shutdown(false) *> termSignal.set(true)

}

object JoexAppImpl {

  def create[F[_]: ConcurrentEffect: ContextShift: Timer](
      cfg: Config,
      termSignal: SignallingRef[F, Boolean],
      connectEC: ExecutionContext,
      blocker: Blocker
  ): Resource[F, JoexApp[F]] =
    for {
      store   <- Store.create(cfg.jdbc, connectEC, blocker)
      nodeOps <- ONode(store)
      sch <- SchedulerBuilder(cfg.scheduler, blocker, store)
        .withTask(
          JobTask.json(
            ProcessItemArgs.taskName,
            ItemHandler[F](cfg),
            ItemHandler.onCancel[F]
          )
        )
        .resource
      app = new JoexAppImpl(cfg, nodeOps, store, termSignal, sch)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR
}
