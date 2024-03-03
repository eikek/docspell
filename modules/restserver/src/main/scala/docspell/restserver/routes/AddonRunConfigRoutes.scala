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
import docspell.backend.ops.OAddons
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.http4s.ThrowableResponseMapper

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl

object AddonRunConfigRoutes {
  def apply[F[_]: Async](backend: BackendApp[F], token: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ThrowableResponseMapper {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          all <- backend.addons.getAllAddonRunConfigs(token.account.collectiveId)
          resp <- Ok(AddonRunConfigList(all.map(convertInfoTask)))
        } yield resp

      case req @ POST -> Root =>
        for {
          input <- req.as[AddonRunConfig]
          data = convertInsertTask(Ident.unsafe(""), input)
          res <- data.flatTraverse(in =>
            backend.addons
              .upsertAddonRunConfig(token.account.collectiveId, in)
              .map(_.leftMap(_.message))
          )
          resp <- res.fold(
            msg => Ok(BasicResult(success = false, msg)),
            id => Ok(IdResult(success = true, s"Addon run config added", id))
          )
        } yield resp

      case req @ PUT -> Root / Ident(id) =>
        for {
          input <- req.as[AddonRunConfig]
          data = convertInsertTask(id, input)
          res <- data.flatTraverse(in =>
            backend.addons
              .upsertAddonRunConfig(token.account.collectiveId, in)
              .map(_.leftMap(_.message))
          )
          resp <- res.fold(
            msg => Ok(BasicResult(success = false, msg)),
            id => Ok(IdResult(success = true, s"Addon run config updated", id))
          )
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          flag <- backend.addons.deleteAddonRunConfig(token.account.collectiveId, id)
          resp <-
            if (flag) Ok(BasicResult(success = true, "Addon task deleted"))
            else NotFound(BasicResult(success = false, "Addon task not found"))
        } yield resp
    }
  }

  def convertInsertTask(
      id: Ident,
      t: AddonRunConfig
  ): Either[String, OAddons.AddonRunInsert] =
    for {
      tr <- NonEmptyList
        .fromList(t.trigger)
        .toRight("At least one trigger is required")
      ta <- NonEmptyList
        .fromList(t.addons)
        .toRight("At least one addon is required")
      res = OAddons.AddonRunInsert(
        id,
        t.name,
        t.enabled,
        t.userId,
        t.schedule,
        tr,
        ta.map(e => OAddons.AddonArgs(e.addonId, e.args))
      )
    } yield res

  def convertInfoTask(t: OAddons.AddonRunInfo): AddonRunConfig =
    AddonRunConfig(
      id = t.id,
      name = t.name,
      enabled = t.enabled,
      userId = t.userId,
      schedule = t.schedule,
      trigger = t.triggered,
      addons = t.addons.map { case (ra, raa) =>
        AddonRef(raa.addonId, ra.name, ra.version, ra.description, raa.args)
      }
    )
}
