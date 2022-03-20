/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect.{Async, Resource}

import docspell.analysis.TextAnalyser
import docspell.backend.fulltext.CreateIndex
import docspell.backend.ops._
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.joex.analysis.RegexNerFile
import docspell.joex.emptytrash.EmptyTrashTask
import docspell.joex.filecopy.{FileCopyTask, FileIntegrityCheckTask}
import docspell.joex.fts.{MigrationTask, ReIndexTask}
import docspell.joex.hk.HouseKeepingTask
import docspell.joex.learn.LearnClassifierTask
import docspell.joex.multiupload.MultiUploadArchiveTask
import docspell.joex.notify.{PeriodicDueItemsTask, PeriodicQueryTask}
import docspell.joex.pagecount.{AllPageCountTask, MakePageCountTask}
import docspell.joex.pdfconv.{ConvertAllPdfTask, PdfConvTask}
import docspell.joex.preview.{AllPreviewsTask, MakePreviewTask}
import docspell.joex.process.{ItemHandler, ReProcessItem}
import docspell.joex.scanmailbox.ScanMailboxTask
import docspell.joex.updatecheck.{ThisVersion, UpdateCheck, UpdateCheckTask}
import docspell.notification.api.NotificationModule
import docspell.pubsub.api.PubSubT
import docspell.scheduler.impl.JobStoreModuleBuilder
import docspell.scheduler.{JobStoreModule, JobTask, JobTaskRegistry}
import docspell.store.Store

import emil.Emil
import org.http4s.client.Client

final class JoexTasks[F[_]: Async](
    cfg: Config,
    store: Store[F],
    itemOps: OItem[F],
    fts: FtsClient[F],
    analyser: TextAnalyser[F],
    regexNer: RegexNerFile[F],
    updateCheck: UpdateCheck[F],
    notification: ONotification[F],
    fileRepo: OFileRepository[F],
    javaEmil: Emil[F],
    jobStoreModule: JobStoreModule[F],
    upload: OUpload[F],
    createIndex: CreateIndex[F],
    joex: OJoex[F],
    itemSearch: OItemSearch[F]
) {

  def get: JobTaskRegistry[F] =
    JobTaskRegistry
      .empty[F]
      .withTask(
        JobTask.json(
          ProcessItemArgs.taskName,
          ItemHandler.newItem[F](cfg, store, itemOps, fts, analyser, regexNer),
          ItemHandler.onCancel[F](store)
        )
      )
      .withTask(
        JobTask.json(
          ProcessItemArgs.multiUploadTaskName,
          MultiUploadArchiveTask[F](store, jobStoreModule.jobs),
          MultiUploadArchiveTask.onCancel[F](store)
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
          EmptyTrashTask[F](itemOps, itemSearch),
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
}

object JoexTasks {

  def resource[F[_]: Async](
      cfg: Config,
      jobStoreModule: JobStoreModuleBuilder.Module[F],
      httpClient: Client[F],
      pubSub: PubSubT[F],
      notificationModule: NotificationModule[F],
      emailService: Emil[F]
  ): Resource[F, JoexTasks[F]] =
    for {
      joex <- OJoex(pubSub)
      store = jobStoreModule.store
      upload <- OUpload(store, jobStoreModule.jobs, joex)
      fts <- createFtsClient(cfg)(httpClient)
      createIndex <- CreateIndex.resource(fts, store)
      itemOps <- OItem(store, fts, createIndex, jobStoreModule.jobs, joex)
      itemSearchOps <- OItemSearch(store)
      analyser <- TextAnalyser.create[F](cfg.textAnalysis.textAnalysisConfig)
      regexNer <- RegexNerFile(cfg.textAnalysis.regexNerFileConfig, store)
      updateCheck <- UpdateCheck.resource(httpClient)
      notification <- ONotification(store, notificationModule)
      fileRepo <- OFileRepository(store, jobStoreModule.jobs, joex)
    } yield new JoexTasks[F](
      cfg,
      store,
      itemOps,
      fts,
      analyser,
      regexNer,
      updateCheck,
      notification,
      fileRepo,
      emailService,
      jobStoreModule,
      upload,
      createIndex,
      joex,
      itemSearchOps
    )

  private def createFtsClient[F[_]: Async](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])
}
