package docspell.scheduler

trait SchedulerModule[F[_]] {
  def scheduler: Scheduler[F]
  def periodicScheduler: PeriodicScheduler[F]
}
