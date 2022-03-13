/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.effect._
import cats.implicits._

import docspell.logging.Logger
import docspell.notification.api._

import org.http4s.Uri
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.dsl.Http4sDsl

final class HttpPostBackend[F[_]: Async](
    channel: NotificationChannel.HttpPost,
    client: Client[F],
    logger: Logger[F]
) extends NotificationBackend[F]
    with EventContextSyntax {

  val dsl = new Http4sDsl[F] with Http4sClientDsl[F] {}
  import dsl._
  import org.http4s.circe.CirceEntityCodec._

  def send(event: EventContext): F[Unit] =
    event.withJsonMessage(logger) { json =>
      val url = Uri.unsafeFromString(channel.url.asString)
      val req = POST(json, url).putHeaders(channel.headers.toList)
      logger.debug(s"$channel sending request: $req") *>
        HttpSend.sendRequest(client, req, channel, logger)
    }
}
