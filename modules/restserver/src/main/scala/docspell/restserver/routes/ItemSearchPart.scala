/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect.Async

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restserver.Config
import docspell.restserver.http4s.{QueryParam => QP}

import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl

@annotation.nowarn
object ItemSearchPart {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      authToken: AuthToken
  ): HttpRoutes[F] =
    if (cfg.featureSearch2) routes(backend, cfg, authToken)
    else HttpRoutes.empty

  def routes[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      authToken: AuthToken
  ): HttpRoutes[F] = {
    val logger = docspell.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "search" :? QP.Query(q) :? QP.Limit(limit) :? QP.Offset(
            offset
          ) :? QP.WithDetails(detailFlag) :? QP.SearchKind(searchMode) =>
        ???

      case req @ POST -> Root / "search" =>
        ???

      case GET -> Root / "searchStats" :? QP.Query(q) :? QP.SearchKind(searchMode) =>
        ???

      case req @ POST -> Root / "searchStats" =>
        ???
    }
  }
}
