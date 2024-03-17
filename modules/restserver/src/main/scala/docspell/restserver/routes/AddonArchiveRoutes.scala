/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.syntax.all._
import fs2.concurrent.Topic

import docspell.addons.AddonMeta
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.AddonValidationError
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.AddonValidationSupport
import docspell.restserver.ws.{Background, OutputEvent}
import docspell.store.records.RAddonArchive

import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl
import org.http4s.dsl.impl.FlagQueryParamMatcher
import org.http4s.{HttpRoutes, Response}

object AddonArchiveRoutes extends AddonValidationSupport {

  def apply[F[_]: Async](
      wsTopic: Topic[F, OutputEvent],
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    implicit val wsOutputEnc = addonResultOutputEventEncoder(token.account.collectiveId)

    HttpRoutes.of {
      case GET -> Root =>
        for {
          all <- backend.addons.getAllAddons(token.account.collectiveId)
          resp <- Ok(
            AddonList(
              all.map(r =>
                Addon(r.id, r.name, r.version, r.description, r.originalUrl, r.created)
              )
            )
          )
        } yield resp

      case req @ POST -> Root :? Sync(sync) =>
        def create(r: Option[RAddonArchive]) =
          IdResult(
            success = true,
            r.fold("Addon submitted for installation")(r =>
              s"Addon installed: ${r.id.id}"
            ),
            r.map(_.id).getOrElse(Ident.unsafe(""))
          )

        for {
          input <- req.as[AddonRegister]
          install = backend.addons.registerAddon(
            token.account.collectiveId,
            input.url,
            None
          )
          resp <-
            if (sync)
              install.flatMap(
                _.fold(convertAddonValidationError[F], r => Ok(create(r._1.some)))
              )
            else Background(wsTopic)(install).flatMap(_ => Ok(create(None)))
        } yield resp

      case PUT -> Root / Ident(id) :? Sync(sync) =>
        def create(r: Option[AddonMeta]) =
          BasicResult(
            success = true,
            r.fold("Addon updated in background")(m =>
              s"Addon updated: ${m.nameAndVersion}"
            )
          )
        val update = backend.addons.refreshAddon(token.account.collectiveId, id)
        for {
          resp <-
            if (sync)
              update.flatMap(
                _.fold(
                  convertAddonValidationError[F],
                  r => Ok(create(r._2.some))
                )
              )
            else Background(wsTopic)(update).flatMap(_ => Ok(create(None)))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          flag <- backend.addons.deleteAddon(token.account.collectiveId, id)
          resp <-
            if (flag) Ok(BasicResult(success = true, "Addon deleted"))
            else NotFound(BasicResult(success = false, "Addon not found"))
        } yield resp
    }
  }

  def convertAddonValidationError[F[_]: Async](
      e: AddonValidationError
  ): F[Response[F]] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    def failWith(msg: String): F[Response[F]] =
      Ok(IdResult(success = false, msg, Ident.unsafe("")))

    e match {
      case AddonValidationError.AddonNotFound =>
        NotFound(BasicResult(success = false, "Addon not found."))

      case _ =>
        failWith(validationErrorToMessage(e))
    }
  }

  object Sync extends FlagQueryParamMatcher("sync")
}
