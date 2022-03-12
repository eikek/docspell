/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect._
import fs2._

/** A periodic scheduler takes care to submit periodic tasks to the job queue.
  *
  * It is run in the background to regularly find a periodic task to execute. If the task
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

object PeriodicScheduler {}
