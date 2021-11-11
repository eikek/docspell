/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.ws

import cats.effect.Async
import fs2.concurrent.Topic
import fs2.{Pipe, Stream}

import docspell.backend.auth.AuthToken

import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl
import org.http4s.server.websocket.WebSocketBuilder2
import org.http4s.websocket.WebSocketFrame
import org.http4s.websocket.WebSocketFrame.Text

object WebSocketRoutes {

  def apply[F[_]: Async](
      user: AuthToken,
      topic: Topic[F, OutputEvent],
      wsb: WebSocketBuilder2[F]
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      val toClient: Stream[F, WebSocketFrame.Text] =
        topic
          .subscribe(500)
          .filter(_.forCollective(user))
          .map(msg => Text(msg.encode))

      val toServer: Pipe[F, WebSocketFrame, Unit] =
        _.map(_ => ())

      wsb.build(toClient, toServer)
    }
  }
}
