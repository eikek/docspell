package docspell.scheduler.impl

import cats.effect._
import docspell.common.Ident
import docspell.scheduler.{
  JobTaskRegistry,
  PeriodicSchedulerConfig,
  SchedulerConfig,
  SchedulerModule
}

case class SchedulerModuleBuilder[F[_]: Async] private (
    periodicSchedulerConfig: PeriodicSchedulerConfig,
    schedulerBuilder: SchedulerBuilder[F],
    jobStoreModule: JobStoreModuleBuilder.Module[F]
) {

  private def configureScheduler(
      f: SchedulerBuilder[F] => SchedulerBuilder[F]
  ): SchedulerModuleBuilder[F] =
    copy(schedulerBuilder = f(schedulerBuilder))

  def withTaskRegistry(reg: JobTaskRegistry[F]): SchedulerModuleBuilder[F] =
    configureScheduler(_.withTaskRegistry(reg))

  def withSchedulerConfig(cfg: SchedulerConfig): SchedulerModuleBuilder[F] =
    configureScheduler(_.withConfig(cfg))

  def withPeriodicSchedulerConfig(
      cfg: PeriodicSchedulerConfig
  ): SchedulerModuleBuilder[F] =
    copy(periodicSchedulerConfig = cfg)

  def resource: Resource[F, SchedulerModule[F]] = {
    val queue = JobQueue(jobStoreModule.store)
    for {
      schedulerR <- schedulerBuilder
        .withPubSub(jobStoreModule.pubSubT)
        .withEventSink(jobStoreModule.eventSink)
        .withQueue(queue)
        .resource

      periodicTaskSchedulerR <-
        PeriodicSchedulerBuilder.resource(
          periodicSchedulerConfig,
          jobStoreModule.periodicTaskStore,
          jobStoreModule.pubSubT
        )
    } yield new SchedulerModule[F] {
      val scheduler = schedulerR
      val periodicScheduler = periodicTaskSchedulerR
    }
  }
}

object SchedulerModuleBuilder {

  def apply[F[_]: Async](
      jobStoreModule: JobStoreModuleBuilder.Module[F]
  ): SchedulerModuleBuilder[F] = {
    val id = Ident.unsafe("default-node-id")
    new SchedulerModuleBuilder(
      PeriodicSchedulerConfig.default(id),
      SchedulerBuilder(SchedulerConfig.default(id), jobStoreModule.store),
      jobStoreModule
    )
  }
}
