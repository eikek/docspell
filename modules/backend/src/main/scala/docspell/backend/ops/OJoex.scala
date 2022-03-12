/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.Applicative
import cats.effect._
import cats.implicits._
import docspell.common.Ident
import docspell.pubsub.api.PubSubT
import docspell.scheduler.msg.{CancelJob, JobsNotify, PeriodicTaskNotify}

trait OJoex[F[_]] {

  def notifyAllNodes: F[Unit]

  def notifyPeriodicTasks: F[Unit]

  def cancelJob(job: Ident, worker: Ident): F[Unit]
}

object OJoex {
  def apply[F[_]: Applicative](pubSub: PubSubT[F]): Resource[F, OJoex[F]] =
    Resource.pure[F, OJoex[F]](new OJoex[F] {

      def notifyAllNodes: F[Unit] =
        pubSub.publish1IgnoreErrors(JobsNotify(), ()).void

      def notifyPeriodicTasks: F[Unit] =
        pubSub.publish1IgnoreErrors(PeriodicTaskNotify(), ()).void

      def cancelJob(job: Ident, worker: Ident): F[Unit] =
        pubSub.publish1IgnoreErrors(CancelJob.topic, CancelJob(job, worker)).as(())
    })
}
