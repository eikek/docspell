/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.{AuthToken, ShareToken}
import docspell.common._
import docspell.restapi.model._

import io.circe.Json
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ClientSettingsRoutes {

  def share[F[_]: Async](
      backend: BackendApp[F],
      token: ShareToken
  ): HttpRoutes[F] = {
    val logger = docspell.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root / Ident(clientId) =>
      (for {
        _ <- OptionT.liftF(logger.debug(s"Get client settings for share ${token.id}"))
        share <- backend.share.findActiveById(token.id)
        sett <- OptionT(
          backend.clientSettings.loadCollective(clientId, share.account.collectiveId)
        )
        res <- OptionT.liftF(Ok(sett.settingsData))
      } yield res)
        .getOrElseF(Ok(Map.empty[String, String]))
    }
  }

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / Ident(clientId) =>
        for {
          mergedData <- backend.clientSettings.loadMerged(
            clientId,
            user.account.collectiveId,
            user.account.userId
          )
          res <- mergedData match {
            case Some(j) => Ok(j)
            case None    => Ok(Map.empty[String, String])
          }
        } yield res

      case req @ PUT -> Root / "user" / Ident(clientId) =>
        for {
          data <- req.as[Json]
          _ <- backend.clientSettings.saveUser(clientId, user.account.userId, data)
          res <- Ok(BasicResult(success = true, "Settings stored"))
        } yield res

      case GET -> Root / "user" / Ident(clientId) =>
        for {
          data <- backend.clientSettings.loadUser(clientId, user.account.userId)
          res <- data match {
            case Some(d) => Ok(d.settingsData)
            case None    => Ok(Map.empty[String, String])
          }
        } yield res

      case DELETE -> Root / "user" / Ident(clientId) =>
        for {
          flag <- backend.clientSettings.deleteUser(clientId, user.account.userId)
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
          _ <- backend.clientSettings.saveCollective(
            clientId,
            user.account.collectiveId,
            data
          )
          res <- Ok(BasicResult(success = true, "Settings stored"))
        } yield res

      case GET -> Root / "collective" / Ident(clientId) =>
        for {
          data <- backend.clientSettings.loadCollective(
            clientId,
            user.account.collectiveId
          )
          res <- data match {
            case Some(d) => Ok(d.settingsData)
            case None    => Ok(Map.empty[String, String])
          }
        } yield res

      case DELETE -> Root / "collective" / Ident(clientId) =>
        for {
          flag <- backend.clientSettings.deleteCollective(
            clientId,
            user.account.collectiveId
          )
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
