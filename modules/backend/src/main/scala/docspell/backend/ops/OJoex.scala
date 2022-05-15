/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import cats.syntax.all._
import fs2.Stream

import docspell.common.{Ident, NodeType}
import docspell.joexapi.client.JoexClient
import docspell.joexapi.model.AddonSupport
import docspell.pubsub.api.PubSubT
import docspell.scheduler.msg.{CancelJob, JobsNotify, PeriodicTaskNotify}

trait OJoex[F[_]] {

  def notifyAllNodes: F[Unit]

  def notifyPeriodicTasks: F[Unit]

  def cancelJob(job: Ident, worker: Ident): F[Unit]

  def getAddonSupport: F[List[AddonSupport]]
}

object OJoex {
  def apply[F[_]: Async](
      pubSub: PubSubT[F],
      nodes: ONode[F],
      joexClient: JoexClient[F]
  ): Resource[F, OJoex[F]] =
    Resource.pure[F, OJoex[F]](new OJoex[F] {

      def notifyAllNodes: F[Unit] =
        pubSub.publish1IgnoreErrors(JobsNotify(), ()).void

      def notifyPeriodicTasks: F[Unit] =
        pubSub.publish1IgnoreErrors(PeriodicTaskNotify(), ()).void

      def cancelJob(job: Ident, worker: Ident): F[Unit] =
        pubSub.publish1IgnoreErrors(CancelJob.topic, CancelJob(job, worker)).as(())

      def getAddonSupport: F[List[AddonSupport]] =
        for {
          joex <- nodes.getNodes(NodeType.Joex)
          conc = math.max(2, Runtime.getRuntime.availableProcessors() - 1)
          supp <- Stream
            .emits(joex)
            .covary[F]
            .parEvalMap(conc)(n => joexClient.getAddonSupport(n.url))
            .compile
            .toList
        } yield supp
    })
}
