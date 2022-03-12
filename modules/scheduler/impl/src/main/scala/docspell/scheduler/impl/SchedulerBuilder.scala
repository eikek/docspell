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
import docspell.scheduler.{JobQueue, _}
import docspell.notification.api.EventSink
import docspell.pubsub.api.PubSubT
import docspell.store.Store

case class SchedulerBuilder[F[_]: Async](
    config: SchedulerConfig,
    tasks: JobTaskRegistry[F],
    store: Store[F],
    queue: Resource[F, JobQueue[F]],
    logSink: LogSink[F],
    pubSub: PubSubT[F],
    eventSink: EventSink[F]
) {

  def withConfig(cfg: SchedulerConfig): SchedulerBuilder[F] =
    copy(config = cfg)

  def withTaskRegistry(reg: JobTaskRegistry[F]): SchedulerBuilder[F] =
    copy(tasks = reg)

  def withTask[A](task: JobTask[F]): SchedulerBuilder[F] =
    withTaskRegistry(tasks.withTask(task))

  def withQueue(queue: Resource[F, JobQueue[F]]): SchedulerBuilder[F] =
    copy(queue = queue)

  def withLogSink(sink: LogSink[F]): SchedulerBuilder[F] =
    copy(logSink = sink)

  def withQueue(queue: JobQueue[F]): SchedulerBuilder[F] =
    copy(queue = Resource.pure[F, JobQueue[F]](queue))

  def withPubSub(pubSubT: PubSubT[F]): SchedulerBuilder[F] =
    copy(pubSub = pubSubT)

  def withEventSink(sink: EventSink[F]): SchedulerBuilder[F] =
    copy(eventSink = sink)

  def serve: Resource[F, Scheduler[F]] =
    resource.evalMap(sch => Async[F].start(sch.start.compile.drain).map(_ => sch))

  def resource: Resource[F, Scheduler[F]] = {
    val scheduler: Resource[F, SchedulerImpl[F]] = for {
      jq <- queue
      waiter <- Resource.eval(SignallingRef(true))
      state <- Resource.eval(SignallingRef(SchedulerImpl.emptyState[F]))
      perms <- Resource.eval(Semaphore(config.poolSize.toLong))
    } yield new SchedulerImpl[F](
      config,
      jq,
      pubSub,
      eventSink,
      tasks,
      store,
      logSink,
      state,
      waiter,
      perms
    )

    scheduler.evalTap(_.init).map(s => s: Scheduler[F])
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
      JobQueue.create(store),
      LogSink.db[F](store),
      PubSubT.noop[F],
      EventSink.silent[F]
    )

}
