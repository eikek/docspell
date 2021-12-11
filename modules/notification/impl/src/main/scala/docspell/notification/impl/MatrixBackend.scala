/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.effect._

import docspell.common.Logger
import docspell.notification.api._

import org.http4s.Uri
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.dsl.Http4sDsl

final class MatrixBackend[F[_]: Async](
    channel: NotificationChannel.Matrix,
    client: Client[F],
    logger: Logger[F]
) extends NotificationBackend[F] {

  val dsl = new Http4sDsl[F] with Http4sClientDsl[F] {}
  import dsl._
  import org.http4s.circe.CirceEntityCodec._

  def send(event: EventContext): F[Unit] = {
    val url =
      (channel.homeServer / "_matrix" / "client" / "r0" / "rooms" / channel.roomId / "send" / "m.room.message")
        .withQuery("access_token", channel.accessToken.pass)
    val uri = Uri.unsafeFromString(url.asString)
    val req = POST(
      Map(
        "msgtype" -> channel.messageType,
        "format" -> "org.matrix.custom.html",
        "formatted_body" -> event.defaultBothHtml,
        "body" -> event.defaultBoth
      ),
      uri
    )
    HttpSend.sendRequest(client, req, channel, logger)
  }
}
