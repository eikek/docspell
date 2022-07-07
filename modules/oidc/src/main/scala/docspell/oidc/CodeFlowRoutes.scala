/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.oidc

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.implicits._

import docspell.common._

import org.http4s.HttpRoutes
import org.http4s._
import org.http4s.client.Client
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location

object CodeFlowRoutes {

  def apply[F[_]: Async](
      enabled: Boolean,
      onUserInfo: OnUserInfo[F],
      config: CodeFlowConfig[F],
      client: Client[F]
  ): HttpRoutes[F] =
    if (enabled) route[F](onUserInfo, config, client)
    else Kleisli(_ => OptionT.pure(Response.notFound[F]))

  def route[F[_]: Async](
      onUserInfo: OnUserInfo[F],
      config: CodeFlowConfig[F],
      client: Client[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._
    val logger = docspell.logging.getLogger[F]
    HttpRoutes.of[F] {
      case req @ GET -> Root / Ident(id) =>
        config.findProvider(id) match {
          case Some(cfg) =>
            for {
              state <- StateParam.generate[F](config.serverSecret)
              uri = cfg.authorizeUrl
                .withQuery("client_id", cfg.clientId)
                .withQuery("scope", cfg.scope)
                .withQuery(
                  "redirect_uri",
                  CodeFlowConfig.resumeUri(req, cfg, config).asString
                )
                .withQuery("response_type", "code")
                .withQuery("state", state.asString)
              _ <- logger.debug(
                s"Redirecting to OAuth/OIDC provider ${cfg.providerId.id}: ${uri.asString}"
              )
              resp <- Found(Location(Uri.unsafeFromString(uri.asString)))
            } yield resp

          case None =>
            logger.debug(s"No OAuth/OIDC provider found with id '$id'") *>
              NotFound()
        }

      case req @ GET -> Root / Ident(id) / "resume" =>
        config.findProvider(id) match {
          case None =>
            logger.debug(s"No OAuth/OIDC provider found with id '$id'") *>
              NotFound()
          case Some(provider) =>
            val codeFromReq = OptionT.fromOption[F](req.params.get("code"))
            val stateParamValid = req.params
              .get("state")
              .exists(state => StateParam.isValidStateParam(state, config.serverSecret))

            val userInfo = for {
              _ <- OptionT.liftF(logger.info(s"Resume OAuth/OIDC flow for ${id.id}"))
              _ <-
                if (stateParamValid) OptionT.pure[F](())
                else
                  OptionT(
                    logger
                      .warn(s"Invalid state parameter returned from Idp!")
                      .as(Option.empty[Unit])
                  )
              code <- codeFromReq
              _ <- OptionT.liftF(
                logger.trace(
                  s"Resume OAuth/OIDC flow from ${provider.providerId.id} with auth_code=$code"
                )
              )
              redirectUri = CodeFlowConfig.resumeUri(req, provider, config)
              u <- CodeFlow(client, provider, redirectUri.asString)(code)
            } yield u

            userInfo.value.flatMap {
              case t @ Some(_) =>
                onUserInfo.handle(req, provider, t)
              case None =>
                val reason = req.params
                  .get("error")
                  .map { err =>
                    val descr =
                      req.params.get("error_description").map(s => s" ($s)").getOrElse("")
                    s"$err$descr"
                  }
                  .map(err => s": $err")
                  .getOrElse(": <no reason>")

                logger.warn(s"Error resuming code flow from '${id.id}'$reason") *>
                  onUserInfo.handle(req, provider, None)
            }
        }

    }
  }
}
