/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.auth._
import docspell.common._
import docspell.restapi.model._
import docspell.restserver._
import docspell.restserver.auth._
import docspell.restserver.http4s.ClientRequestInfo
import docspell.totp.OnetimePassword

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object LoginRoutes {

  def login[F[_]: Async](S: Login[F], cfg: Config): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ POST -> Root / "two-factor" =>
        for {
          sf <- req.as[SecondFactor]
          tokenParsed = AuthToken.fromString(sf.token)
          resp <- tokenParsed match {
            case Right(token) =>
              S.loginSecondFactor(cfg.auth)(
                Login.SecondFactor(token, sf.rememberMe, OnetimePassword(sf.otp.pass))
              ).flatMap(result =>
                makeResponse(dsl, cfg, req, result, token.account.asString)
              )
            case Left(err) =>
              BadRequest(
                BasicResult(success = false, s"Invalid authentication token: $err")
              )
          }
        } yield resp

      case req @ POST -> Root / "login" =>
        for {
          up <- req.as[UserPass]
          res <- S.loginUserPass(cfg.auth)(
            Login.UserPass(up.account, up.password, up.rememberMe.getOrElse(false))
          )
          resp <- makeResponse(dsl, cfg, req, res, up.account)
        } yield resp
    }
  }

  def session[F[_]: Async](S: Login[F], cfg: Config, token: AuthToken): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ POST -> Root / "session" =>
        AuthToken
          .update(token, cfg.auth.serverSecret)
          .map(newToken => Login.Result.ok(newToken, None))
          .flatMap(res => makeResponse(dsl, cfg, req, res, ""))

      case req @ POST -> Root / "logout" =>
        for {
          _ <- RememberCookieData.fromCookie(req).traverse(S.removeRememberToken)
          res <- Ok()
        } yield res
          .removeCookie(CookieData.deleteCookie(getBaseUrl(cfg, req)))
          .removeCookie(RememberCookieData.delete(getBaseUrl(cfg, req)))
    }
  }

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]): LenientUri =
    ClientRequestInfo.getBaseUrl(cfg, req)

  private def makeResponse[F[_]: Async](
      dsl: Http4sDsl[F],
      cfg: Config,
      req: Request[F],
      res: Login.Result,
      account: String
  ): F[Response[F]] = {
    import dsl._
    res match {
      case Login.Result.Ok(token, remember) =>
        val cd = CookieData(token)
        val rem = remember.map(RememberCookieData.apply)
        for {
          resp <- Ok(
            AuthResult(
              token.account.collective.id,
              token.account.login.id,
              success = true,
              "Login successful",
              Some(cd.asString),
              cfg.auth.sessionValid.millis,
              token.requireSecondFactor
            )
          ).map(cd.addCookie(getBaseUrl(cfg, req)))
            .map(resp =>
              rem
                .map(_.addCookie(cfg.auth.rememberMe, getBaseUrl(cfg, req))(resp))
                .getOrElse(resp)
            )

        } yield resp
      case _ =>
        Ok(
          AuthResult(
            "",
            account,
            success = false,
            "Login failed.",
            None,
            0L,
            requireSecondFactor = false
          )
        )
    }
  }

}
