/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.data.NonEmptyList
import fs2.{Pipe, Stream}

import docspell.common.Logger

trait PubSubT[F[_]] {

  def publish1[A](topic: TypedTopic[A], msg: A): F[MessageHead]

  def publish[A](topic: TypedTopic[A]): Pipe[F, A, MessageHead]

  def subscribe[A](topic: TypedTopic[A]): Stream[F, Message[A]]

  def delegate: PubSub[F]

  def withDelegate(delegate: PubSub[F]): PubSubT[F]
}

object PubSubT {

  def apply[F[_]](pubSub: PubSub[F], logger: Logger[F]): PubSubT[F] =
    new PubSubT[F] {
      def publish1[A](topic: TypedTopic[A], msg: A): F[MessageHead] =
        pubSub.publish1(topic.topic, topic.codec(msg))

      def publish[A](topic: TypedTopic[A]): Pipe[F, A, MessageHead] =
        _.map(topic.codec.apply).through(pubSub.publish(topic.topic))

      def subscribe[A](topic: TypedTopic[A]): Stream[F, Message[A]] =
        pubSub
          .subscribe(NonEmptyList.of(topic.topic))
          .flatMap(m =>
            m.body.as[A](topic.codec) match {
              case Right(a) => Stream.emit(Message(m.head, a))
              case Left(err) =>
                logger.s
                  .error(err)(
                    s"Could not decode message to topic ${topic.name} to ${topic.msgClass}: ${m.body.noSpaces}"
                  )
                  .drain
            }
          )

      def delegate: PubSub[F] = pubSub

      def withDelegate(newDelegate: PubSub[F]): PubSubT[F] =
        PubSubT(newDelegate, logger)
    }
}
