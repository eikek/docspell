package docspell.joex

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._
import fs2.concurrent.SignallingRef

import docspell.analysis.TextAnalyser
import docspell.backend.ops._
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.joex.analysis.RegexNerFile
import docspell.joex.fts.{MigrationTask, ReIndexTask}
import docspell.joex.hk._
import docspell.joex.learn.LearnClassifierTask
import docspell.joex.notify._
import docspell.joex.pdfconv.ConvertAllPdfTask
import docspell.joex.pdfconv.PdfConvTask
import docspell.joex.process.ItemHandler
import docspell.joex.process.ReProcessItem
import docspell.joex.scanmailbox._
import docspell.joex.scheduler._
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.queue._
import docspell.store.records.RJobLog

import emil.javamail._
import org.http4s.client.Client
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
      .flatMap(pstore.insert) *>
      MigrationTask.job.flatMap(queue.insertIfNew)
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
      store    <- Store.create(cfg.jdbc, connectEC, blocker)
      queue    <- JobQueue(store)
      pstore   <- PeriodicTaskStore.create(store)
      nodeOps  <- ONode(store)
      joex     <- OJoex(client, store)
      upload   <- OUpload(store, queue, cfg.files, joex)
      fts      <- createFtsClient(cfg)(httpClient)
      itemOps  <- OItem(store, fts, queue, joex)
      analyser <- TextAnalyser.create[F](cfg.textAnalysis.textAnalysisConfig)
      regexNer <- RegexNerFile(cfg.textAnalysis.regexNerFileConfig, blocker, store)
      javaEmil =
        JavaMailEmil(blocker, Settings.defaultSettings.copy(debug = cfg.mailDebug))
      sch <- SchedulerBuilder(cfg.scheduler, blocker, store)
        .withQueue(queue)
        .withTask(
          JobTask.json(
            ProcessItemArgs.taskName,
            ItemHandler.newItem[F](cfg, itemOps, fts, analyser, regexNer),
            ItemHandler.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            ReProcessItemArgs.taskName,
            ReProcessItem[F](cfg, fts, analyser, regexNer),
            ReProcessItem.onCancel[F]
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
            MigrationTask.taskName,
            MigrationTask[F](cfg.fullTextSearch, fts),
            MigrationTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            ReIndexTask.taskName,
            ReIndexTask[F](cfg.fullTextSearch, fts),
            ReIndexTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            HouseKeepingTask.taskName,
            HouseKeepingTask[F](cfg),
            HouseKeepingTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            PdfConvTask.taskName,
            PdfConvTask[F](cfg),
            PdfConvTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            ConvertAllPdfArgs.taskName,
            ConvertAllPdfTask[F](queue, joex),
            ConvertAllPdfTask.onCancel[F]
          )
        )
        .withTask(
          JobTask.json(
            LearnClassifierArgs.taskName,
            LearnClassifierTask[F](cfg.textAnalysis, blocker, analyser),
            LearnClassifierTask.onCancel[F]
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

  private def createFtsClient[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])
}
