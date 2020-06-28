package docspell.joex.scheduler

import cats.effect.{Fiber, Timer}
import fs2.Stream

import docspell.common.Ident
import docspell.store.records.RJob

trait Scheduler[F[_]] {

  def config: SchedulerConfig

  def getRunning: F[Vector[RJob]]

  def requestCancel(jobId: Ident): F[Boolean]

  def notifyChange: F[Unit]

  def start: Stream[F, Nothing]

  /** Requests to shutdown the scheduler.
    *
    * The scheduler will not take any new jobs from the queue. If
    * there are still running jobs, it waits for them to complete.
    * when the cancelAll flag is set to true, it cancels all running
    * jobs.
    *
    * The returned F[Unit] can be evaluated to wait for all that to
    * complete.
    */
  def shutdown(cancelAll: Boolean): F[Unit]

  def periodicAwake(implicit T: Timer[F]): F[Fiber[F, Unit]]
}
