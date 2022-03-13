/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._
import fs2.concurrent.SignallingRef
import fs2.{Pipe, Stream}

import docspell.logging.Logger

trait PubSubT[F[_]] {

  def publish1[A](topic: TypedTopic[A], msg: A): F[F[MessageHead]]

  def publish1IgnoreErrors[A](topic: TypedTopic[A], msg: A): F[F[Unit]]

  def publish[A](topic: TypedTopic[A]): Pipe[F, A, MessageHead]

  def subscribe[A](topic: TypedTopic[A]): Stream[F, Message[A]]

  def subscribeSink[A](topic: TypedTopic[A])(handler: Message[A] => F[Unit]): F[F[Unit]]

  def delegate: PubSub[F]

  def withDelegate(delegate: PubSub[F]): PubSubT[F]
}

object PubSubT {
  def noop[F[_]: Async]: PubSubT[F] =
    PubSubT(PubSub.noop[F], Logger.offF[F])

  def apply[F[_]: Async](pubSub: PubSub[F], logger: Logger[F]): PubSubT[F] =
    new PubSubT[F] {
      def publish1[A](topic: TypedTopic[A], msg: A): F[F[MessageHead]] =
        pubSub.publish1(topic.topic, topic.codec(msg))

      def publish1IgnoreErrors[A](topic: TypedTopic[A], msg: A): F[F[Unit]] =
        publish1(topic, msg).map(_.attempt.flatMap {
          case Right(_) => ().pure[F]
          case Left(ex) =>
            logger.error(ex)(s"Error publishing to topic ${topic.topic.name}: $msg")
        })

      def publish[A](topic: TypedTopic[A]): Pipe[F, A, MessageHead] =
        _.map(topic.codec.apply).through(pubSub.publish(topic.topic))

      def subscribe[A](topic: TypedTopic[A]): Stream[F, Message[A]] =
        pubSub
          .subscribe(NonEmptyList.of(topic.topic))
          .flatMap(m =>
            m.body.as[A](topic.codec) match {
              case Right(a) => Stream.emit(Message(m.head, a))
              case Left(err) =>
                logger.stream
                  .error(err)(
                    s"Could not decode message to topic ${topic.name} to ${topic.msgClass}: ${m.body.noSpaces}"
                  )
                  .drain
            }
          )

      def subscribeSink[A](
          topic: TypedTopic[A]
      )(handler: Message[A] => F[Unit]): F[F[Unit]] =
        for {
          halt <- SignallingRef.of[F, Boolean](false)
          _ <- subscribe(topic)
            .evalMap(handler)
            .interruptWhen(halt)
            .compile
            .drain
        } yield halt.set(true)

      def delegate: PubSub[F] = pubSub

      def withDelegate(newDelegate: PubSub[F]): PubSubT[F] =
        PubSubT(newDelegate, logger)
    }
}
