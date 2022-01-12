/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.effect._
import cats.implicits._

import docspell.common.Logger
import docspell.notification.api._

import io.circe.Json
import org.http4s.Uri
import org.http4s.circe.CirceEntityCodec._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.dsl.Http4sDsl

final class GotifyBackend[F[_]: Async](
    channel: NotificationChannel.Gotify,
    client: Client[F],
    logger: Logger[F]
) extends NotificationBackend[F]
    with EventContextSyntax {

  val dsl = new Http4sDsl[F] with Http4sClientDsl[F] {}
  import dsl._

  def send(event: EventContext): F[Unit] =
    event.withDefault(logger) { (title, body) =>
      val url = Uri.unsafeFromString((channel.url / "message").asString)
      val req = POST(
        Json.obj(
          "title" -> Json.fromString(title),
          "priority" -> Json.fromInt(channel.priority.getOrElse(0)),
          "message" -> Json.fromString(body),
          "extras" -> Json.obj(
            "client::display" -> Json.obj(
              "contentType" -> Json.fromString("text/markdown")
            )
          )
        ),
        url
      )
        .putHeaders("X-Gotify-Key" -> channel.appKey.pass)
      logger.debug(s"Seding request: $req") *>
        HttpSend.sendRequest(client, req, channel, logger)
    }
}
