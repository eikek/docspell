/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.Applicative
import cats.effect._
import cats.implicits._

import docspell.backend.msg.{CancelJob, Topics}
import docspell.common.Ident
import docspell.pubsub.api.PubSubT

trait OJoex[F[_]] {

  def notifyAllNodes: F[Unit]

  def cancelJob(job: Ident, worker: Ident): F[Unit]
}

object OJoex {
  def apply[F[_]: Applicative](pubSub: PubSubT[F]): Resource[F, OJoex[F]] =
    Resource.pure[F, OJoex[F]](new OJoex[F] {

      def notifyAllNodes: F[Unit] =
        pubSub.publish1IgnoreErrors(Topics.jobsNotify, ()).as(())

      def cancelJob(job: Ident, worker: Ident): F[Unit] =
        pubSub.publish1IgnoreErrors(CancelJob.topic, CancelJob(job, worker)).as(())
    })
}
