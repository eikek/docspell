/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.data.NonEmptyList
import fs2.{Pipe, Stream}

import docspell.common.Logger

trait PubSubT[F[_], P <: PubSub[F]] {

  def publish1[A](topic: TypedTopic[A], msg: A): F[MessageHead]

  def publish[A](topic: TypedTopic[A]): Pipe[F, A, MessageHead]

  def subscribe[A](topic: TypedTopic[A]): Stream[F, Message[A]]

  def delegate: P

  def withDelegate[R <: PubSub[F]](delegate: R): PubSubT[F, R]
}

object PubSubT {

  def apply[F[_], P <: PubSub[F]](pubSub: P, logger: Logger[F]): PubSubT[F, P] =
    new PubSubT[F, P] {
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

      def delegate: P = pubSub

      def withDelegate[R <: PubSub[F]](newDelegate: R): PubSubT[F, R] =
        PubSubT(newDelegate, logger)
    }
}
