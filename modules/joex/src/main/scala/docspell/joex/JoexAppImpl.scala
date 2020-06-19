package docspell.joex

import cats.implicits._
import cats.effect._
import emil.javamail._
import docspell.common._
import docspell.backend.ops._
import docspell.joex.hk._
import docspell.joex.notify._
import docspell.joex.fts.IndexTask
import docspell.joex.scanmailbox._
import docspell.joex.process.ItemHandler
import docspell.joex.scheduler._
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.queue._
import docspell.store.records.RJobLog
import docspell.ftssolr.SolrFtsClient
import fs2.concurrent.SignallingRef
import scala.concurrent.ExecutionContext
import org.http4s.client.blaze.BlazeClientBuilder

final class JoexAppImpl[F[_]: ConcurrentEffect: ContextShift: Timer](
    cfg: Config,
    nodeOps: ONode[F],
    store: Store[F],
    queue: JobQueue[F],
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
    HouseKeepingTask
      .periodicTask[F](cfg.houseKeeping.schedule)
      .flatMap(pstore.insert) *> IndexTask.job.flatMap(queue.insertIfNew)
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
      httpClient <- BlazeClientBuilder[F](clientEC).resource
      client = JoexClient(httpClient)
      store   <- Store.create(cfg.jdbc, connectEC, blocker)
      queue   <- JobQueue(store)
      pstore  <- PeriodicTaskStore.create(store)
      nodeOps <- ONode(store)
      joex    <- OJoex(client, store)
      upload  <- OUpload(store, queue, cfg.files, joex)
      fts     <- SolrFtsClient(cfg.fullTextSearch.solr, httpClient)
      javaEmil =
        JavaMailEmil(blocker, Settings.defaultSettings.copy(debug = cfg.mailDebug))
      sch <- SchedulerBuilder(cfg.scheduler, blocker, store)
        .withQueue(queue)
        .withTask(
          JobTask.json(
            ProcessItemArgs.taskName,
            ItemHandler.newItem[F](cfg, fts),
            ItemHandler.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            NotifyDueItemsArgs.taskName,
            NotifyDueItemsTask[F](cfg.sendMail, javaEmil),
            NotifyDueItemsTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            ScanMailboxArgs.taskName,
            ScanMailboxTask[F](cfg.userTasks.scanMailbox, javaEmil, upload, joex),
            ScanMailboxTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            IndexTask.taskName,
            IndexTask[F](cfg.fullTextSearch, fts),
            IndexTask.onCancel[F]
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
      app = new JoexAppImpl(cfg, nodeOps, store, queue, pstore, termSignal, sch, psch)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR
}
