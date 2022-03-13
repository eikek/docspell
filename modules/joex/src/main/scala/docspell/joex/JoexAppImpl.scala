/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect._
import cats.implicits._
import fs2.concurrent.SignallingRef
import docspell.analysis.TextAnalyser
import docspell.backend.MailAddressCodec
import docspell.backend.fulltext.CreateIndex
import docspell.backend.ops._
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.joex.analysis.RegexNerFile
import docspell.joex.emptytrash._
import docspell.joex.filecopy.{FileCopyTask, FileIntegrityCheckTask}
import docspell.joex.fts.{MigrationTask, ReIndexTask}
import docspell.joex.hk._
import docspell.joex.learn.LearnClassifierTask
import docspell.joex.notify._
import docspell.joex.pagecount._
import docspell.joex.pdfconv.ConvertAllPdfTask
import docspell.joex.pdfconv.PdfConvTask
import docspell.joex.preview._
import docspell.joex.process.ItemHandler
import docspell.joex.process.ReProcessItem
import docspell.joex.scanmailbox._
import docspell.scheduler._
import docspell.scheduler.impl.{JobStoreModuleBuilder, SchedulerModuleBuilder}
import docspell.joex.updatecheck._
import docspell.notification.api.NotificationModule
import docspell.notification.impl.NotificationModuleImpl
import docspell.pubsub.api.{PubSub, PubSubT}
import docspell.scheduler.usertask.{UserTaskScope, UserTaskStore}
import docspell.store.Store
import docspell.store.records.{REmptyTrashSetting, RJobLog}
import emil.javamail._
import org.http4s.client.Client

final class JoexAppImpl[F[_]: Async](
    cfg: Config,
    store: Store[F],
    uts: UserTaskStore[F],
    jobStore: JobStore[F],
    termSignal: SignallingRef[F, Boolean],
    notificationMod: NotificationModule[F],
    val scheduler: Scheduler[F],
    val periodicScheduler: PeriodicScheduler[F]
) extends JoexApp[F] {
  def init: F[Unit] = {
    val run = scheduler.start.compile.drain
    val prun = periodicScheduler.start.compile.drain
    val eventConsume = notificationMod.consumeAllEvents(2).compile.drain
    for {
      _ <- scheduleBackgroundTasks
      _ <- Async[F].start(run)
      _ <- Async[F].start(prun)
      _ <- Async[F].start(eventConsume)
      _ <- scheduler.periodicAwake
      _ <- periodicScheduler.periodicAwake
      _ <- scheduler.startSubscriptions
      _ <- periodicScheduler.startSubscriptions
    } yield ()
  }

  def findLogs(jobId: Ident): F[Vector[RJobLog]] =
    store.transact(RJobLog.findLogs(jobId))

  def initShutdown: F[Unit] =
    periodicScheduler.shutdown *> scheduler.shutdown(false) *> termSignal.set(true)

  private def scheduleBackgroundTasks: F[Unit] =
    HouseKeepingTask
      .periodicTask[F](cfg.houseKeeping.schedule)
      .flatMap(t => uts.updateTask(UserTaskScope.system, t.summary, t)) *>
      scheduleEmptyTrashTasks *>
      UpdateCheckTask
        .periodicTask(cfg.updateCheck)
        .flatMap(t => uts.updateTask(UserTaskScope.system, t.summary, t)) *>
      MigrationTask.job.flatMap(jobStore.insertIfNew) *>
      AllPreviewsTask
        .job(MakePreviewArgs.StoreMode.WhenMissing, None)
        .flatMap(jobStore.insertIfNew) *>
      AllPageCountTask.job.flatMap(jobStore.insertIfNew).void

  private def scheduleEmptyTrashTasks: F[Unit] =
    store
      .transact(
        REmptyTrashSetting.findForAllCollectives(OCollective.EmptyTrash.default, 50)
      )
      .evalMap { es =>
        val args = EmptyTrashArgs(es.cid, es.minAge)
        uts.updateOneTask(
          UserTaskScope(args.collective),
          args.makeSubject.some,
          EmptyTrashTask.userTask(args, es.schedule)
        )
      }
      .compile
      .drain

}

object JoexAppImpl extends MailAddressCodec {

  def create[F[_]: Async](
      cfg: Config,
      termSignal: SignallingRef[F, Boolean],
      store: Store[F],
      httpClient: Client[F],
      pubSub: PubSub[F]
  ): Resource[F, JoexApp[F]] =
    for {
      joexLogger <- Resource.pure(docspell.logging.getLogger[F](s"joex-${cfg.appId.id}"))
      pubSubT = PubSubT(pubSub, joexLogger)
      javaEmil =
        JavaMailEmil(Settings.defaultSettings.copy(debug = cfg.mailDebug))
      notificationMod <- Resource.eval(
        NotificationModuleImpl[F](store, javaEmil, httpClient, 200)
      )

      jobStoreModule = JobStoreModuleBuilder(store)
        .withPubsub(pubSubT)
        .withEventSink(notificationMod)
        .build

      joex <- OJoex(pubSubT)
      upload <- OUpload(store, jobStoreModule.jobs, joex)
      fts <- createFtsClient(cfg)(httpClient)
      createIndex <- CreateIndex.resource(fts, store)
      itemOps <- OItem(store, fts, createIndex, jobStoreModule.jobs, joex)
      itemSearchOps <- OItemSearch(store)
      analyser <- TextAnalyser.create[F](cfg.textAnalysis.textAnalysisConfig)
      regexNer <- RegexNerFile(cfg.textAnalysis.regexNerFileConfig, store)
      updateCheck <- UpdateCheck.resource(httpClient)
      notification <- ONotification(store, notificationMod)
      fileRepo <- OFileRepository(store, jobStoreModule.jobs, joex)

      schedulerModule <- SchedulerModuleBuilder(jobStoreModule)
        .withSchedulerConfig(cfg.scheduler)
        .withPeriodicSchedulerConfig(cfg.periodicScheduler)
        .withTaskRegistry(JobTaskRegistry
          .empty[F]
          .withTask(
            JobTask.json(
              ProcessItemArgs.taskName,
              ItemHandler.newItem[F](cfg,store, itemOps, fts, analyser, regexNer),
              ItemHandler.onCancel[F](store)
            )
          )
          .withTask(
            JobTask.json(
              ReProcessItemArgs.taskName,
              ReProcessItem[F](cfg, fts, itemOps, analyser, regexNer, store),
              ReProcessItem.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              ScanMailboxArgs.taskName,
              ScanMailboxTask[F](cfg.userTasks.scanMailbox, store, javaEmil, upload, joex),
              ScanMailboxTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              MigrationTask.taskName,
              MigrationTask[F](cfg.fullTextSearch, store, fts, createIndex),
              MigrationTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              ReIndexTask.taskName,
              ReIndexTask[F](cfg.fullTextSearch, store, fts, createIndex),
              ReIndexTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              HouseKeepingTask.taskName,
              HouseKeepingTask[F](cfg, store, fileRepo),
              HouseKeepingTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              PdfConvTask.taskName,
              PdfConvTask[F](cfg, store),
              PdfConvTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              ConvertAllPdfArgs.taskName,
              ConvertAllPdfTask[F](jobStoreModule.jobs, joex, store),
              ConvertAllPdfTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              LearnClassifierArgs.taskName,
              LearnClassifierTask[F](cfg.textAnalysis, store, analyser),
              LearnClassifierTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              MakePreviewArgs.taskName,
              MakePreviewTask[F](cfg.extraction.preview, store),
              MakePreviewTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              AllPreviewsArgs.taskName,
              AllPreviewsTask[F](jobStoreModule.jobs, joex, store),
              AllPreviewsTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              MakePageCountArgs.taskName,
              MakePageCountTask[F](store),
              MakePageCountTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              AllPageCountTask.taskName,
              AllPageCountTask[F](store, jobStoreModule.jobs, joex),
              AllPageCountTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              EmptyTrashArgs.taskName,
              EmptyTrashTask[F](itemOps, itemSearchOps),
              EmptyTrashTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              UpdateCheckTask.taskName,
              UpdateCheckTask[F](
                cfg.updateCheck,
                cfg.sendMail,
                store,
                javaEmil,
                updateCheck,
                ThisVersion.default
              ),
              UpdateCheckTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              PeriodicQueryTask.taskName,
              PeriodicQueryTask[F](store, notification),
              PeriodicQueryTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              PeriodicDueItemsTask.taskName,
              PeriodicDueItemsTask[F](store, notification),
              PeriodicDueItemsTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              FileCopyTaskArgs.taskName,
              FileCopyTask[F](cfg, store),
              FileCopyTask.onCancel[F]
            )
          )
          .withTask(
            JobTask.json(
              FileIntegrityCheckArgs.taskName,
              FileIntegrityCheckTask[F](fileRepo, store),
              FileIntegrityCheckTask.onCancel[F]
            )
          )
        )
        .resource
      app = new JoexAppImpl(
        cfg,
        store,
        jobStoreModule.userTasks,
        jobStoreModule.jobs,
        termSignal,
        notificationMod,
        schedulerModule.scheduler,
        schedulerModule.periodicScheduler
      )
      appR <- Resource.make(app.init.map(_ => app))(_.initShutdown)
    } yield appR

  private def createFtsClient[F[_]: Async](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])

}
