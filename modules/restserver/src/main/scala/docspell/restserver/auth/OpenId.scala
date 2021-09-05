/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver.auth

import cats.effect._
import docspell.backend.BackendApp
import docspell.oidc.{CodeFlowConfig, OnUserInfo}
import docspell.restserver.Config
import docspell.restserver.http4s.ClientRequestInfo

object OpenId {

  def codeFlowConfig[F[_]](config: Config): CodeFlowConfig[F] =
    CodeFlowConfig(
      req =>
        ClientRequestInfo
          .getBaseUrl(config, req) / "api" / "v1" / "open" / "auth" / "oauth",
      id =>
        config.openid.filter(_.enabled).find(_.provider.providerId == id).map(_.provider)
    )

  def handle[F[_]: Async](backend: BackendApp[F], cfg: Config): OnUserInfo[F] =
    OnUserInfo((req, provider, userInfo) =>
      userInfo match {
        case Some(userJson) =>
          println(s"$backend $cfg")
          OnUserInfo.logInfo[F].handle(req, provider, Some(userJson))
        case None =>
          OnUserInfo.logInfo[F].handle(req, provider, None)
      }
    )

  //    u <- userInfo
  //    newAcc <- OptionT.liftF(
  //      NewAccount.create(u ++ Ident.unsafe(":") ++ p.providerId, AccountSource.OAuth(p.id.id))
  //    )
  //    acc <- OptionT.liftF(S.account.createIfMissing(newAcc))
  //    accId = acc.accountId(None)
  //    _ <- OptionT.liftF(S.account.updateLoginStats(accId))
  //    token <- OptionT.liftF(
  //      AuthToken.user[F](accId, cfg.backend.auth.serverSecret)
  //    )
  //  } yield token
  //
  //  val uri = getBaseUrl( req).withQuery("oauth", "1") / "app" / "login"
  //  val location = Location(Uri.unsafeFromString(uri.asString))
  //  userId.value.flatMap {
  //    case Some(t) =>
  //      TemporaryRedirect(location)
  //        .map(_.addCookie(CookieData(t).asCookie(getBaseUrl(req))))
  //    case None => TemporaryRedirect(location)
  //  }
}
