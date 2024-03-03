/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.NonEmptyList
import cats.effect._
import cats.syntax.all._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restapi.model._
import docspell.restserver.http4s.ThrowableResponseMapper
import docspell.scheduler.usertask.UserTaskScope

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl

object AddonRunRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], token: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ThrowableResponseMapper {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "existingitem" =>
      for {
        input <- req.as[AddonRunExistingItem]
        _ <- backend.addons.runAddonForItem(
          token.account.collectiveId,
          NonEmptyList(input.itemId, input.additionalItems),
          input.addonRunConfigIds.toSet,
          UserTaskScope(token.account)
        )
        resp <- Ok(BasicResult(success = true, "Job for running addons submitted."))
      } yield resp
    }
  }
}
