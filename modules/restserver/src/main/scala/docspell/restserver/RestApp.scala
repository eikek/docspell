/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import fs2.Stream

import docspell.backend.BackendApp

import org.http4s.HttpRoutes
import org.http4s.server.websocket.WebSocketBuilder2

trait RestApp[F[_]] {

  /** Access to the configuration used to build backend services. */
  def config: Config

  /** Access to all backend services */
  def backend: BackendApp[F]

  /** Stream consuming events (async) originating in this application. */
  def eventConsume(maxConcurrent: Int): Stream[F, Nothing]

  /** Stream consuming messages from topics (pubsub) and forwarding them to the frontend
    * via websocket.
    */
  def subscriptions: Stream[F, Nothing]

  /** Http4s endpoint definitions. */
  def routes(wsb: WebSocketBuilder2[F]): HttpRoutes[F]
}
