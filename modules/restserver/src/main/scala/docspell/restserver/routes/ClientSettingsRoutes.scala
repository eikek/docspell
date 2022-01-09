/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import cats.kernel.Semigroup

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
      case GET -> Root / Ident(clientId) =>
        for {
          collData <- backend.clientSettings.loadCollective(clientId, user.account)
          userData <- backend.clientSettings.loadUser(clientId, user.account)

          mergedData = collData.map(_.settingsData) |+| userData.map(_.settingsData)

          res <- mergedData match {
            case Some(j) => Ok(j)
            case None    => NotFound()
          }
        } yield res

      case req @ PUT -> Root / "user" / Ident(clientId) =>
        for {
          data <- req.as[Json]
          _ <- backend.clientSettings.saveUser(clientId, user.account, data)
          res <- Ok(BasicResult(true, "Settings stored"))
        } yield res

      case GET -> Root / "user" / Ident(clientId) =>
        for {
          data <- backend.clientSettings.loadUser(clientId, user.account)
          res <- data match {
            case Some(d) => Ok(d.settingsData)
            case None    => Ok(Map.empty[String, String])
          }
        } yield res

      case DELETE -> Root / "user" / Ident(clientId) =>
        for {
          flag <- backend.clientSettings.deleteUser(clientId, user.account)
          res <- Ok(
            BasicResult(
              flag,
              if (flag) "Settings deleted" else "Deleting settings failed"
            )
          )
        } yield res

      case req @ PUT -> Root / "collective" / Ident(clientId) =>
        for {
          data <- req.as[Json]
          _ <- backend.clientSettings.saveCollective(clientId, user.account, data)
          res <- Ok(BasicResult(true, "Settings stored"))
        } yield res

      case GET -> Root / "collective" / Ident(clientId) =>
        for {
          data <- backend.clientSettings.loadCollective(clientId, user.account)
          res <- data match {
            case Some(d) => Ok(d.settingsData)
            case None    => Ok(Map.empty[String, String])
          }
        } yield res

      case DELETE -> Root / "collective" / Ident(clientId) =>
        for {
          flag <- backend.clientSettings.deleteCollective(clientId, user.account)
          res <- Ok(
            BasicResult(
              flag,
              if (flag) "Settings deleted" else "Deleting settings failed"
            )
          )
        } yield res
    }
  }

  implicit def jsonSemigroup: Semigroup[Json] =
    Semigroup.instance((a1, a2) => a1.deepMerge(a2))
}
