/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect._
import fs2.Stream

import docspell.common.Ident

trait Scheduler[F[_]] {

  def config: SchedulerConfig

  def getRunning: F[Vector[Job[String]]]

  def requestCancel(jobId: Ident): F[Boolean]

  def notifyChange: F[Unit]

  /** Starts reacting on notify and cancel messages. */
  def startSubscriptions: F[Unit]

  /** Starts the schedulers main loop. */
  def start: Stream[F, Nothing]

  /** Requests to shutdown the scheduler.
    *
    * The scheduler will not take any new jobs from the queue. If there are still running
    * jobs, it waits for them to complete. when the cancelAll flag is set to true, it
    * cancels all running jobs.
    *
    * The returned F[Unit] can be evaluated to wait for all that to complete.
    */
  def shutdown(cancelAll: Boolean): F[Unit]

  def periodicAwake: F[Fiber[F, Throwable, Unit]]
}
