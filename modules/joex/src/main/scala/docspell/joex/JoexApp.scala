/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import docspell.common.Ident
import docspell.scheduler.{PeriodicScheduler, Scheduler}
import docspell.store.records.RJobLog

trait JoexApp[F[_]] {

  def init: F[Unit]

  def scheduler: Scheduler[F]

  def periodicScheduler: PeriodicScheduler[F]

  def findLogs(jobId: Ident): F[Vector[RJobLog]]

  /** Shuts down the job executor.
    *
    * It will immediately stop taking new jobs, waiting for currently running jobs to
    * complete normally (i.e. running jobs are not canceled). After this completed, the
    * webserver stops and the main loop will exit.
    */
  def initShutdown: F[Unit]
}
