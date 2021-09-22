/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model._

import io.circe.Json
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ClientSettingsRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ PUT -> Root / Ident(clientId) =>
        for {
          data <- req.as[Json]
          _ <- backend.clientSettings.save(clientId, user.account, data)
          res <- Ok(BasicResult(true, "Settings stored"))
        } yield res

      case GET -> Root / Ident(clientId) =>
        for {
          data <- backend.clientSettings.load(clientId, user.account)
          res <- data match {
            case Some(d) => Ok(d.settingsData)
            case None    => NotFound()
          }
        } yield res

      case DELETE -> Root / Ident(clientId) =>
        for {
          flag <- backend.clientSettings.delete(clientId, user.account)
          res <- Ok(
            BasicResult(
              flag,
              if (flag) "Settings deleted" else "Deleting settings failed"
            )
          )
        } yield res
    }
  }
}
