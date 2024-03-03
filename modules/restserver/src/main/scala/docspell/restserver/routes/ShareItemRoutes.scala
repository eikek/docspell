/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.ShareToken
import docspell.common._
import docspell.restapi.model.BasicResult
import docspell.restserver.conv.Conversions

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ShareItemRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: ShareToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root / Ident(id) =>
      for {
        item <- backend.share.findItem(id, token.id).value
        result = item.map(Conversions.mkItemDetail)
        resp <-
          result
            .map(r => Ok(r))
            .getOrElse(NotFound(BasicResult(success = false, "Not found.")))
      } yield resp
    }
  }
}
