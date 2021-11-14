/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.Applicative
import cats.data.NonEmptyList
import fs2.{Pipe, Stream}

import docspell.common.{Ident, Timestamp}

import io.circe.Json

trait PubSub[F[_]] {
  def publish1(topic: Topic, msg: Json): F[F[MessageHead]]

  def publish(topic: Topic): Pipe[F, Json, MessageHead]

  def subscribe(topics: NonEmptyList[Topic]): Stream[F, Message[Json]]
}
object PubSub {
  def noop[F[_]: Applicative]: PubSub[F] =
    new PubSub[F] {
      def publish1(topic: Topic, msg: Json): F[F[MessageHead]] =
        Applicative[F].pure(
          Applicative[F].pure(MessageHead(Ident.unsafe("0"), Timestamp.Epoch, topic))
        )

      def publish(topic: Topic): Pipe[F, Json, MessageHead] =
        _ => Stream.empty

      def subscribe(topics: NonEmptyList[Topic]): Stream[F, Message[Json]] =
        Stream.empty
    }
}
