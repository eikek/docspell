/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect.Async
import fs2.concurrent.Topic

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restapi.model.BasicResult
import docspell.restserver.Config
import docspell.restserver.http4s.Responses
import docspell.restserver.ws.OutputEvent

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.server.Router

object AddonRoutes {

  def apply[F[_]: Async](
      cfg: Config,
      wsTopic: Topic[F, OutputEvent],
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    if (cfg.backend.addons.enabled)
      Router(
        "archive" -> AddonArchiveRoutes(wsTopic, backend, token),
        "run-config" -> AddonRunConfigRoutes(backend, token),
        "run" -> AddonRunRoutes(backend, token)
      )
    else
      Responses.notFoundRoute(BasicResult(success = false, "Addons disabled"))
}
