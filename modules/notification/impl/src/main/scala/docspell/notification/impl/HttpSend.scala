/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.notification.api.NotificationChannel

import org.http4s.Request
import org.http4s.client.Client

object HttpSend {

  def sendRequest[F[_]: Async](
      client: Client[F],
      req: Request[F],
      channel: NotificationChannel,
      logger: Logger[F]
  ) =
    client
      .status(req)
      .flatMap { status =>
        if (status.isSuccess) logger.info(s"Send notification via $channel")
        else
          Async[F].raiseError[Unit](
            new Exception(s"Error sending notification via $channel: $status")
          )
      }
}
