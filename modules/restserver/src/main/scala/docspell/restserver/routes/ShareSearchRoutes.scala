/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.Kleisli
import cats.effect._

import docspell.backend.BackendApp
import docspell.backend.auth.ShareToken
import docspell.restserver.Config

import org.http4s.HttpRoutes

object ShareSearchRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      token: ShareToken
  ): HttpRoutes[F] =
    Kleisli { req =>
      for {
        shareQuery <- backend.share.findShareQuery(token.id)
        searchPart = ItemSearchPart(backend.search, backend.share, cfg, shareQuery)
        routes = searchPart.routes
        resp <- routes(req)
      } yield resp
    }
}
