/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.auth.{Login, ShareToken}
import docspell.backend.ops.OShare
import docspell.backend.ops.OShare.VerifyResult
import docspell.restserver.auth.ShareCookieData

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.server._

object ShareAuth {

  def authenticateRequest[F[_]: Async](
      validate: String => F[VerifyResult]
  )(req: Request[F]): F[OShare.VerifyResult] =
    ShareCookieData.fromRequest(req) match {
      case Some(tokenStr) =>
        validate(tokenStr)
      case None =>
        VerifyResult.notFound.pure[F]
    }

  private def getToken[F[_]: Async](
      auth: String => F[VerifyResult]
  ): Kleisli[F, Request[F], Either[String, ShareToken]] =
    Kleisli(r => authenticateRequest(auth)(r).map(_.toEither))

  def of[F[_]: Async](S: OShare[F], cfg: Login.Config)(
      pf: PartialFunction[AuthedRequest[F, ShareToken], F[Response[F]]]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = getToken[F](S.verifyToken(cfg.serverSecret))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware: AuthMiddleware[F, ShareToken] =
      AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes.of(pf))
  }

  def apply[F[_]: Async](S: OShare[F], cfg: Login.Config)(
      f: ShareToken => HttpRoutes[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = getToken[F](S.verifyToken(cfg.serverSecret))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware: AuthMiddleware[F, ShareToken] =
      AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes(authReq => f(authReq.context).run(authReq.req)))
  }
}
