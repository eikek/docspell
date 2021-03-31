package docspell.joex.scheduler

import cats.effect._
import cats.effect.concurrent.Semaphore
import cats.implicits._
import fs2.concurrent.SignallingRef

import docspell.store.Store
import docspell.store.queue.JobQueue

case class SchedulerBuilder[F[_]: ConcurrentEffect: ContextShift](
    config: SchedulerConfig,
    tasks: JobTaskRegistry[F],
    store: Store[F],
    blocker: Blocker,
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
    SchedulerBuilder[F](config, tasks, store, blocker, queue, logSink)

  def withBlocker(blocker: Blocker): SchedulerBuilder[F] =
    copy(blocker = blocker)

  def withLogSink(sink: LogSink[F]): SchedulerBuilder[F] =
    copy(logSink = sink)

  def withQueue(queue: JobQueue[F]): SchedulerBuilder[F] =
    copy(queue = Resource.pure[F, JobQueue[F]](queue))

  def serve: Resource[F, Scheduler[F]] =
    resource.evalMap(sch =>
      ConcurrentEffect[F].start(sch.start.compile.drain).map(_ => sch)
    )

  def resource: Resource[F, Scheduler[F]] = {
    val scheduler = for {
      jq     <- queue
      waiter <- Resource.eval(SignallingRef(true))
      state  <- Resource.eval(SignallingRef(SchedulerImpl.emptyState[F]))
      perms  <- Resource.eval(Semaphore(config.poolSize.toLong))
    } yield new SchedulerImpl[F](
      config,
      blocker,
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

  def apply[F[_]: ConcurrentEffect: ContextShift](
      config: SchedulerConfig,
      blocker: Blocker,
      store: Store[F]
  ): SchedulerBuilder[F] =
    new SchedulerBuilder[F](
      config,
      JobTaskRegistry.empty[F],
      store,
      blocker,
      JobQueue(store),
      LogSink.db[F](store)
    )

}
