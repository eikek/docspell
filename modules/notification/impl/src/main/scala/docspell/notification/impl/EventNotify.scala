/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._

import docspell.notification.api.Event
import docspell.notification.api.NotificationBackend
import docspell.store.Store
import docspell.store.queries.QNotification

import emil.Emil
import org.http4s.client.Client

/** Represents the actual work done for each event. */
object EventNotify {

  def apply[F[_]: Async](
      store: Store[F],
      mailService: Emil[F],
      client: Client[F]
  ): Kleisli[F, Event, Unit] = {
    val logger = docspell.logging.getLogger[F]
    Kleisli { event =>
      (for {
        hooks <- OptionT.liftF(store.transact(QNotification.findChannelsForEvent(event)))
        _ <- OptionT.liftF(logger.trace(s"Found hooks: $hooks for event: $event"))
        evctx <- DbEventContext.apply.run(event).mapK(store.transform)
        channels = hooks
          .filter(hc =>
            hc.channels.nonEmpty && hc.hook.eventFilter.forall(_.matches(evctx.asJson))
          )
          .flatMap(_.channels)
        backend =
          if (channels.isEmpty) NotificationBackend.silent[F]
          else
            NotificationBackendImpl.forChannelsIgnoreErrors(
              client,
              mailService,
              logger
            )(channels)
        _ <- OptionT.liftF(backend.send(evctx))
      } yield ()).getOrElse(())
    }
  }

}
