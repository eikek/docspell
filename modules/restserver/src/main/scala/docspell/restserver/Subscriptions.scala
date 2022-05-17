/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect.Async
import fs2.Stream
import fs2.concurrent.Topic

import docspell.pubsub.api.PubSubT
import docspell.restserver.ws.OutputEvent
import docspell.scheduler.msg.{JobDone, JobSubmitted}

import io.circe.parser

/** Subscribes to those events from docspell that are forwarded to the websocket endpoints
  */
object Subscriptions {

  def apply[F[_]: Async](
      wsTopic: Topic[F, OutputEvent],
      pubSub: PubSubT[F]
  ): Stream[F, Nothing] =
    jobDone(pubSub).merge(jobSubmitted(pubSub)).through(wsTopic.publish)

  def jobDone[F[_]](pubSub: PubSubT[F]): Stream[F, OutputEvent] =
    pubSub
      .subscribe(JobDone.topic)
      .map(m =>
        OutputEvent.JobDone(
          m.body.group,
          m.body.task,
          parser.parse(m.body.args).toOption,
          m.body.result
        )
      )

  def jobSubmitted[F[_]](pubSub: PubSubT[F]): Stream[F, OutputEvent] =
    pubSub
      .subscribe(JobSubmitted.topic)
      .map(m => OutputEvent.JobSubmitted(m.body.group, m.body.task))

}
