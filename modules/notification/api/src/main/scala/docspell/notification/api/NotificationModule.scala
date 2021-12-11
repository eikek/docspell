/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Applicative
import cats.data.{Kleisli, OptionT}
import cats.implicits._
import fs2.Stream

import docspell.common.Logger

trait NotificationModule[F[_]]
    extends EventSink[F]
    with EventReader[F]
    with EventExchange[F] {

  /** Sends an event as notification through configured channels. */
  def notifyEvent: Kleisli[F, Event, Unit]

  /** Send the event data via the given channels. */
  def send(
      logger: Logger[F],
      event: EventContext,
      channels: Seq[NotificationChannel]
  ): F[Unit]

  /** Amend an event with additional data. */
  def eventContext: EventContext.Factory[F, Event]

  /** Create an example event context. */
  def sampleEvent: EventContext.Example[F, Event]

  /** Consume all offered events asynchronously. */
  def consumeAllEvents(maxConcurrent: Int): Stream[F, Nothing] =
    consume(maxConcurrent)(notifyEvent)
}

object NotificationModule {

  def noop[F[_]: Applicative]: NotificationModule[F] =
    new NotificationModule[F] {
      val noSend = NotificationBackend.silent[F]
      val noExchange = EventExchange.silent[F]

      def notifyEvent = Kleisli(_ => ().pure[F])
      def eventContext = Kleisli(_ => OptionT.none[F, EventContext])
      def sampleEvent = EventContext.example(ev => EventContext.empty(ev).pure[F])
      def send(
          logger: Logger[F],
          event: EventContext,
          channels: Seq[NotificationChannel]
      ) =
        noSend.send(event)
      def offer(event: Event) = noExchange.offer(event)
      def consume(maxConcurrent: Int)(run: Kleisli[F, Event, Unit]) =
        noExchange.consume(maxConcurrent)(run)
    }
}
