/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.scheduler

import cats.effect._
import fs2._
import fs2.concurrent.SignallingRef

import docspell.backend.ops.OJoex
import docspell.store.queue._

/** A periodic scheduler takes care to submit periodic tasks to the job queue.
  *
  * It is run in the background to regularily find a periodic task to execute. If the task
  * is due, it will be submitted into the job queue where it will be picked up by the
  * scheduler from some joex instance. If it is due in the future, a notification is
  * scheduled to be received at that time so the task can be looked up again.
  */
trait PeriodicScheduler[F[_]] {

  def config: PeriodicSchedulerConfig

  def start: Stream[F, Nothing]

  def shutdown: F[Unit]

  def periodicAwake: F[Fiber[F, Throwable, Unit]]

  def notifyChange: F[Unit]
}

object PeriodicScheduler {

  def create[F[_]: Async](
      cfg: PeriodicSchedulerConfig,
      sch: Scheduler[F],
      queue: JobQueue[F],
      store: PeriodicTaskStore[F],
      joex: OJoex[F]
  ): Resource[F, PeriodicScheduler[F]] =
    for {
      waiter <- Resource.eval(SignallingRef(true))
      state <- Resource.eval(SignallingRef(PeriodicSchedulerImpl.emptyState[F]))
      psch = new PeriodicSchedulerImpl[F](
        cfg,
        sch,
        queue,
        store,
        joex,
        waiter,
        state
      )
      _ <- Resource.eval(psch.init)
    } yield psch

}
