/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect.Sync

import docspell.common._
import docspell.logging.Logger

trait Context[F[_], A] { self =>

  def jobId: Ident

  def args: A

  def config: SchedulerConfig

  def logger: Logger[F]

  def setProgress(percent: Int): F[Unit]

  def isLastRetry: F[Boolean]

  def map[C](f: A => C): Context[F, C]

  def unit: Context[F, Unit] =
    map(_ => ())

  def loadJob(implicit F: Sync[F]): F[Job[String]]
}
