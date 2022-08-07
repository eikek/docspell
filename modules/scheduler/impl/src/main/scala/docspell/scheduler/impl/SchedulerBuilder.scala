/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import cats.effect.std.Semaphore
import cats.implicits._
import fs2.concurrent.SignallingRef

import docspell.notification.api.EventSink
import docspell.pubsub.api.PubSubT
import docspell.scheduler._
import docspell.store.Store

case class SchedulerBuilder[F[_]: Async](
    config: SchedulerConfig,
    tasks: JobTaskRegistry[F],
    store: Store[F],
    queue: JobQueue[F],
    logSink: LogSink[F],
    pubSub: PubSubT[F],
    eventSink: EventSink[F],
    findJobOwner: FindJobOwner[F]
) {

  def withConfig(cfg: SchedulerConfig): SchedulerBuilder[F] =
    copy(config = cfg)

  def withTaskRegistry(reg: JobTaskRegistry[F]): SchedulerBuilder[F] =
    copy(tasks = reg)

  def withTask(task: JobTask[F]): SchedulerBuilder[F] =
    withTaskRegistry(tasks.withTask(task))

  def withLogSink(sink: LogSink[F]): SchedulerBuilder[F] =
    copy(logSink = sink)

  def withQueue(queue: JobQueue[F]): SchedulerBuilder[F] =
    copy(queue = queue)

  def withPubSub(pubSubT: PubSubT[F]): SchedulerBuilder[F] =
    copy(pubSub = pubSubT)

  def withEventSink(sink: EventSink[F]): SchedulerBuilder[F] =
    copy(eventSink = sink)

  def withFindJobOwner(f: FindJobOwner[F]): SchedulerBuilder[F] =
    copy(findJobOwner = f)

  def serve: Resource[F, Scheduler[F]] =
    resource.evalMap(sch => Async[F].start(sch.start.compile.drain).map(_ => sch))

  def resource: Resource[F, Scheduler[F]] = {
    val scheduler: F[SchedulerImpl[F]] = for {
      waiter <- SignallingRef(true)
      state <- SignallingRef(SchedulerImpl.emptyState[F])
      perms <- Semaphore(config.poolSize.toLong)
    } yield new SchedulerImpl[F](
      config,
      queue,
      pubSub,
      eventSink,
      findJobOwner,
      tasks,
      store,
      logSink,
      state,
      waiter,
      perms
    )

    Resource.eval(scheduler.flatTap(_.init)).map(s => s: Scheduler[F])
  }

}

object SchedulerBuilder {

  def apply[F[_]: Async](
      config: SchedulerConfig,
      store: Store[F]
  ): SchedulerBuilder[F] =
    new SchedulerBuilder[F](
      config,
      JobTaskRegistry.empty[F],
      store,
      JobQueue(store),
      LogSink.db[F](store),
      PubSubT.noop[F],
      EventSink.silent[F],
      FindJobOwner.none[F]
    )
}
