/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect._
import cats.implicits._
import fs2.concurrent.SignallingRef
import docspell.backend.MailAddressCodec
import docspell.backend.joex.FindJobOwnerAccount
import docspell.backend.ops._
import docspell.common._
import docspell.joex.emptytrash._
import docspell.joex.fts.MigrationTask
import docspell.joex.hk._
import docspell.joex.pagecount._
import docspell.joex.preview._
import docspell.joex.updatecheck._
import docspell.notification.api.NotificationModule
import docspell.notification.impl.NotificationModuleImpl
import docspell.pubsub.api.{PubSub, PubSubT}
import docspell.scheduler._
import docspell.scheduler.impl.{JobStoreModuleBuilder, SchedulerModuleBuilder}
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
      pubSub: PubSub[F],
      pools: Pools
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
        .withFindJobOwner(FindJobOwnerAccount(store))
        .build

      tasks <- JoexTasks.resource(
        cfg,
        pools,
        jobStoreModule,
        httpClient,
        pubSubT,
        notificationMod,
        javaEmil
      )

      schedulerModule <- SchedulerModuleBuilder(jobStoreModule)
        .withSchedulerConfig(cfg.scheduler)
        .withPeriodicSchedulerConfig(cfg.periodicScheduler)
        .withTaskRegistry(tasks.get)
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
      nodes <- ONode(store)
      _ <- nodes.withRegistered(cfg.appId, NodeType.Joex, cfg.baseUrl, None)
      appR <- Resource.make(app.init.map(_ => app))(_.initShutdown)
    } yield appR

}
