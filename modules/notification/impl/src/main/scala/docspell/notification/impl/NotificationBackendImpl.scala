/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.data.NonEmptyList
import cats.effect._

import docspell.common.Logger
import docspell.notification.api.NotificationBackend.{combineAll, ignoreErrors, silent}
import docspell.notification.api.{NotificationBackend, NotificationChannel}

import emil.Emil
import org.http4s.client.Client

object NotificationBackendImpl {

  def forChannel[F[_]: Async](client: Client[F], mailService: Emil[F], logger: Logger[F])(
      channel: NotificationChannel
  ): NotificationBackend[F] =
    channel match {
      case c: NotificationChannel.Email =>
        new EmailBackend[F](c, mailService, logger)
      case c: NotificationChannel.HttpPost =>
        new HttpPostBackend[F](c, client, logger)
      case c: NotificationChannel.Gotify =>
        new GotifyBackend[F](c, client, logger)
      case c: NotificationChannel.Matrix =>
        new MatrixBackend[F](c, client, logger)
    }

  def forChannels[F[_]: Async](client: Client[F], maiService: Emil[F], logger: Logger[F])(
      channels: Seq[NotificationChannel]
  ): NotificationBackend[F] =
    NonEmptyList.fromFoldable(channels) match {
      case Some(nel) =>
        combineAll[F](nel.map(forChannel(client, maiService, logger)))
      case None =>
        silent[F]
    }

  def forChannelsIgnoreErrors[F[_]: Async](
      client: Client[F],
      mailService: Emil[F],
      logger: Logger[F]
  )(
      channels: Seq[NotificationChannel]
  ): NotificationBackend[F] =
    NonEmptyList.fromFoldable(channels) match {
      case Some(nel) =>
        combineAll(
          nel.map(forChannel[F](client, mailService, logger)).map(ignoreErrors[F](logger))
        )
      case None =>
        silent[F]
    }

}
