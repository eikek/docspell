/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import fs2.Stream
import fs2.concurrent.Topic
import docspell.backend.msg.JobDone
import docspell.common.ProcessItemArgs
import docspell.pubsub.api.PubSubT
import docspell.restserver.ws.OutputEvent

/** Subscribes to those events from docspell that are forwarded to the websocket endpoints
  */
object Subscriptions {

  def apply[F[_]](
      wsTopic: Topic[F, OutputEvent],
      pubSub: PubSubT[F]
  ): Stream[F, Nothing] =
    jobDone(pubSub).through(wsTopic.publish)

  def jobDone[F[_]](pubSub: PubSubT[F]): Stream[F, OutputEvent] =
    pubSub
      .subscribe(JobDone.topic)
      .filter(m => m.body.task == ProcessItemArgs.taskName)
      .map(m => OutputEvent.ItemProcessed(m.body.group))
}
