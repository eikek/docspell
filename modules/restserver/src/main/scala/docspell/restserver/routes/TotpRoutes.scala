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
import docspell.backend.ops.OTotp
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.totp.OnetimePassword

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object TotpRoutes {
  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "state" =>
        for {
          result <- backend.totp.state(user.account)
          resp <- Ok(
            result.fold(
              en => OtpState(enabled = true, en.created.some),
              _ => OtpState(enabled = false, None)
            )
          )
        } yield resp
      case POST -> Root / "init" =>
        for {
          result <- backend.totp.initialize(user.account)
          resp <- result match {
            case OTotp.InitResult.AlreadyExists =>
              UnprocessableEntity(
                BasicResult(success = false, "A totp setup already exists!")
              )
            case OTotp.InitResult.NotFound =>
              NotFound(BasicResult(success = false, "User not found"))
            case OTotp.InitResult.Failed(ex) =>
              InternalServerError(BasicResult(success = false, ex.getMessage))
            case s @ OTotp.InitResult.Success(_, key) =>
              val issuer = cfg.appName
              val uri = s.authenticatorUrl(issuer)
              Ok(OtpResult(uri, key.data.toBase32, "totp", issuer))
          }
        } yield resp

      case req @ POST -> Root / "confirm" =>
        for {
          data <- req.as[OtpConfirm]
          result <- backend.totp.confirmInit(user.account, OnetimePassword(data.otp.pass))
          resp <- result match {
            case OTotp.ConfirmResult.Success =>
              Ok(BasicResult(success = true, "TOTP setup successful."))
            case OTotp.ConfirmResult.Failed =>
              Ok(BasicResult(success = false, "TOTP setup failed!"))
          }
        } yield resp

      case req @ POST -> Root / "disable" =>
        for {
          data <- req.as[OtpConfirm]
          result <- backend.totp.disable(
            user.account.asAccountId,
            OnetimePassword(data.otp.pass).some
          )
          resp <- Ok(Conversions.basicResult(result, "TOTP setup disabled."))
        } yield resp
    }
  }

  def admin[F[_]: Async](backend: BackendApp[F]): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "resetOTP" =>
      for {
        data <- req.as[ResetPassword]
        result <- backend.totp.disable(data.account, None)
        resp <- Ok(Conversions.basicResult(result, "TOTP setup disabled."))
      } yield resp
    }
  }
}
