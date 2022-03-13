/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

trait SchedulerModule[F[_]] {
  def scheduler: Scheduler[F]
  def periodicScheduler: PeriodicScheduler[F]
}
