package docspell.joex

import cats.implicits._
import cats.effect._
import emil.javamail._
import docspell.common._
import docspell.joex.hk._
import docspell.joex.process.ItemHandler
import docspell.joex.scheduler._
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.queue._
import docspell.backend.ops.ONode
import docspell.store.records.RJobLog
import fs2.concurrent.SignallingRef
import scala.concurrent.ExecutionContext

final class JoexAppImpl[F[_]: ConcurrentEffect: ContextShift: Timer](
    cfg: Config,
    nodeOps: ONode[F],
    store: Store[F],
    pstore: PeriodicTaskStore[F],
    termSignal: SignallingRef[F, Boolean],
    val scheduler: Scheduler[F],
    val periodicScheduler: PeriodicScheduler[F]
) extends JoexApp[F] {

  def init: F[Unit] = {
    val run  = scheduler.start.compile.drain
    val prun = periodicScheduler.start.compile.drain
    for {
      _ <- scheduleBackgroundTasks
      _ <- ConcurrentEffect[F].start(run)
      _ <- ConcurrentEffect[F].start(prun)
      _ <- scheduler.periodicAwake
      _ <- periodicScheduler.periodicAwake
      _ <- nodeOps.register(cfg.appId, NodeType.Joex, cfg.baseUrl)
    } yield ()
  }

  def findLogs(jobId: Ident): F[Vector[RJobLog]] =
    store.transact(RJobLog.findLogs(jobId))

  def shutdown: F[Unit] =
    nodeOps.unregister(cfg.appId)

  def initShutdown: F[Unit] =
    periodicScheduler.shutdown *> scheduler.shutdown(false) *> termSignal.set(true)

  private def scheduleBackgroundTasks: F[Unit] =
    HouseKeepingTask.periodicTask[F](cfg.houseKeeping.schedule).flatMap(pstore.insert)
}

object JoexAppImpl {

  def create[F[_]: ConcurrentEffect: ContextShift: Timer](
      cfg: Config,
      termSignal: SignallingRef[F, Boolean],
      connectEC: ExecutionContext,
      clientEC: ExecutionContext,
      blocker: Blocker
  ): Resource[F, JoexApp[F]] =
    for {
      client  <- JoexClient.resource(clientEC)
      store   <- Store.create(cfg.jdbc, connectEC, blocker)
      queue   <- JobQueue(store)
      pstore  <- PeriodicTaskStore.create(store)
      nodeOps <- ONode(store)
      sch <- SchedulerBuilder(cfg.scheduler, blocker, store)
        .withQueue(queue)
        .withTask(
          JobTask.json(
            ProcessItemArgs.taskName,
            ItemHandler[F](cfg),
            ItemHandler.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            NotifyDueItemsArgs.taskName,
            NotifyDueItemsTask[F](cfg.sendMail, JavaMailEmil(blocker)),
            NotifyDueItemsTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            HouseKeepingTask.taskName,
            HouseKeepingTask[F](cfg),
            HouseKeepingTask.onCancel[F]
          )
        )
        .resource
      psch <- PeriodicScheduler.create(
        cfg.periodicScheduler,
        sch,
        queue,
        pstore,
        client,
        Timer[F]
      )
      app = new JoexAppImpl(cfg, nodeOps, store, pstore, termSignal, sch, psch)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR
}
