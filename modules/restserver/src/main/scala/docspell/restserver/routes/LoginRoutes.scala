package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.auth._
import docspell.restapi.model._
import docspell.restserver._
import docspell.restserver.auth._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object LoginRoutes {

  def login[F[_]: Effect](S: Login[F], cfg: Config): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] { case req @ POST -> Root / "login" =>
      for {
        up   <- req.as[UserPass]
        res  <- S.loginUserPass(cfg.auth)(Login.UserPass(up.account, up.password))
        resp <- makeResponse(dsl, cfg, res, up.account)
      } yield resp
    }
  }

  def session[F[_]: Effect](S: Login[F], cfg: Config): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ POST -> Root / "session" =>
        Authenticate
          .authenticateRequest(S.loginSession(cfg.auth))(req)
          .flatMap(res => makeResponse(dsl, cfg, res, ""))

      case POST -> Root / "logout" =>
        Ok().map(_.addCookie(CookieData.deleteCookie(cfg)))
    }
  }

  def makeResponse[F[_]: Effect](
      dsl: Http4sDsl[F],
      cfg: Config,
      res: Login.Result,
      account: String
  ): F[Response[F]] = {
    import dsl._
    res match {
      case Login.Result.Ok(token) =>
        for {
          cd <- AuthToken.user(token.account, cfg.auth.serverSecret).map(CookieData.apply)
          resp <- Ok(
            AuthResult(
              token.account.collective.id,
              token.account.user.id,
              true,
              "Login successful",
              Some(cd.asString),
              cfg.auth.sessionValid.millis
            )
          ).map(_.addCookie(cd.asCookie(cfg)))
        } yield resp
      case _ =>
        Ok(AuthResult("", account, false, "Login failed.", None, 0L))
    }
  }

}
