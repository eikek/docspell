/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.data.Kleisli
import cats.effect.kernel.Async
import cats.implicits._

import docspell.logging.Logger
import docspell.notification.api._
import docspell.store.Store

import emil.Emil
import org.http4s.client.Client

object NotificationModuleImpl {

  def apply[F[_]: Async](
      store: Store[F],
      mailService: Emil[F],
      client: Client[F],
      queueSize: Int
  ): F[NotificationModule[F]] =
    for {
      exchange <- EventExchange.circularQueue[F](queueSize)
    } yield new NotificationModule[F] {
      val notifyEvent = EventNotify(store, mailService, client)

      val eventContext = DbEventContext.apply.mapF(_.mapK(store.transform))

      val sampleEvent = ExampleEventContext.apply

      def send(
          logger: Logger[F],
          event: EventContext,
          channels: Seq[NotificationChannel]
      ) =
        NotificationBackendImpl
          .forChannels(client, mailService, logger)(channels)
          .send(event)

      def offer(event: Event) = exchange.offer(event)

      def consume(maxConcurrent: Int)(run: Kleisli[F, Event, Unit]) =
        exchange.consume(maxConcurrent)(run)
    }
}
