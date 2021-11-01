/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.data.NonEmptyList
import fs2.{Pipe, Stream}

import io.circe.Json

trait PubSub[F[_]] {
  def publish1(topic: Topic, msg: Json): F[MessageHead]

  def publish(topic: Topic): Pipe[F, Json, MessageHead]

  def subscribe(topics: NonEmptyList[Topic]): Stream[F, Message[Json]]
}
