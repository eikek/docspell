/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.scheduler

import cats.effect._
import cats.effect.std.Semaphore
import cats.implicits._
import fs2.concurrent.SignallingRef

import docspell.store.Store
import docspell.store.queue.JobQueue

case class SchedulerBuilder[F[_]: Async](
    config: SchedulerConfig,
    tasks: JobTaskRegistry[F],
    store: Store[F],
    queue: Resource[F, JobQueue[F]],
    logSink: LogSink[F]
) {

  def withConfig(cfg: SchedulerConfig): SchedulerBuilder[F] =
    copy(config = cfg)

  def withTaskRegistry(reg: JobTaskRegistry[F]): SchedulerBuilder[F] =
    copy(tasks = reg)

  def withTask[A](task: JobTask[F]): SchedulerBuilder[F] =
    withTaskRegistry(tasks.withTask(task))

  def withQueue(queue: Resource[F, JobQueue[F]]): SchedulerBuilder[F] =
    SchedulerBuilder[F](config, tasks, store, queue, logSink)

  def withLogSink(sink: LogSink[F]): SchedulerBuilder[F] =
    copy(logSink = sink)

  def withQueue(queue: JobQueue[F]): SchedulerBuilder[F] =
    copy(queue = Resource.pure[F, JobQueue[F]](queue))

  def serve: Resource[F, Scheduler[F]] =
    resource.evalMap(sch => Async[F].start(sch.start.compile.drain).map(_ => sch))

  def resource: Resource[F, Scheduler[F]] = {
    val scheduler: Resource[F, SchedulerImpl[F]] = for {
      jq     <- queue
      waiter <- Resource.eval(SignallingRef(true))
      state  <- Resource.eval(SignallingRef(SchedulerImpl.emptyState[F]))
      perms  <- Resource.eval(Semaphore(config.poolSize.toLong))
    } yield new SchedulerImpl[F](
      config,
      jq,
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
      JobQueue(store),
      LogSink.db[F](store)
    )

}
