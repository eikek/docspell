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
import docspell.common.Ident
import docspell.restapi.model.JobPriority
import docspell.restserver.conv.Conversions

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object JobQueueRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "state" =>
        for {
          js <- backend.job.queueState(user.account.collective, 40)
          res = Conversions.mkJobQueueState(js)
          resp <- Ok(res)
        } yield resp

      case POST -> Root / Ident(id) / "cancel" =>
        for {
          result <- backend.job.cancelJob(id, user.account.collective)
          resp <- Ok(Conversions.basicResult(result))
        } yield resp

      case req @ POST -> Root / Ident(id) / "priority" =>
        for {
          prio <- req.as[JobPriority]
          res <- backend.job.setPriority(id, user.account.collective, prio.priority)
          resp <- Ok(Conversions.basicResult(res, "Job priority changed"))
        } yield resp
    }
  }

}
