/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data._
import cats.effect._
import cats.implicits._

import docspell.backend.auth._
import docspell.restserver.auth._

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.server._

object Authenticate {

  def authenticateRequest[F[_]: Async](
      auth: (String, Option[String]) => F[Login.Result]
  )(req: Request[F]): F[Login.Result] =
    CookieData.authenticator(req) match {
      case Right(str) =>
        val rememberMe = RememberCookieData.fromCookie(req)
        auth(str, rememberMe)
      case Left(_) =>
        RememberCookieData.fromCookie(req) match {
          case Some(rc) =>
            auth("", rc.some)
          case None =>
            Login.Result.invalidAuth.pure[F]
        }
    }

  def of[F[_]: Async](S: Login[F], cfg: Login.Config)(
      pf: PartialFunction[AuthedRequest[F, AuthToken], F[Response[F]]]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = getUser[F](S.loginSessionOrRememberMe(cfg))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware: AuthMiddleware[F, AuthToken] =
      AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes.of(pf))
  }

  def apply[F[_]: Async](S: Login[F], cfg: Login.Config)(
      f: AuthToken => HttpRoutes[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = getUser[F](S.loginSessionOrRememberMe(cfg))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware: AuthMiddleware[F, AuthToken] =
      AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes(authReq => f(authReq.context).run(authReq.req)))
  }

  private def getUser[F[_]: Async](
      auth: (String, Option[String]) => F[Login.Result]
  ): Kleisli[F, Request[F], Either[String, AuthToken]] =
    Kleisli(r => authenticateRequest(auth)(r).map(_.toEither))
}
