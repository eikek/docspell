/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.oidc

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._

import io.circe.Json
import org.http4s.Method._
import org.http4s._
import org.http4s.circe.CirceEntityCodec._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.client.middleware.RequestLogger
import org.http4s.client.middleware.ResponseLogger
import org.http4s.headers.Accept
import org.http4s.headers.Authorization
import org.log4s.getLogger

/** https://openid.net/specs/openid-connect-core-1_0.html (OIDC)
  * https://openid.net/specs/openid-connect-basic-1_0.html#TokenRequest (OIDC)
  * https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.4 (OAuth2)
  * https://datatracker.ietf.org/doc/html/rfc7519 (JWT)
  */
object CodeFlow {
  private[this] val log4sLogger = getLogger

  def apply[F[_]: Async, A](
      client: Client[F],
      cfg: ProviderConfig,
      redirectUri: String
  )(
      code: String
  ): OptionT[F, Json] = {
    val logger = Logger.log4s[F](log4sLogger)
    val dsl    = new Http4sClientDsl[F] {}
    val c      = logRequests[F](logResponses[F](client))

    for {
      _ <- OptionT.liftF(
        logger.trace(
          s"Obtaining access_token for provider ${cfg.providerId.id} and code $code"
        )
      )
      token <- fetchAccessToken[F](c, dsl, cfg, redirectUri, code)
      _ <- OptionT.liftF(
        logger.trace(
          s"Obtaining user-info for provider ${cfg.providerId.id} and token $token"
        )
      )
      user <- cfg.userUrl match {
        case Some(url) if cfg.signKey.isEmpty =>
          fetchFromUserEndpoint[F](c, dsl, url, token)
        case _ if cfg.signKey.nonEmpty =>
          token.decodeToken(cfg.signKey, cfg.sigAlgo) match {
            case Right(jwt) =>
              OptionT.pure[F](jwt.claims)
            case Left(err) =>
              OptionT
                .liftF(logger.error(s"Error verifying jwt access token: $err"))
                .flatMap(_ => OptionT.none[F, Json])
          }
        case _ =>
          OptionT
            .liftF(
              logger.warn(
                s"No signature specified and no user endpoint url. Cannot obtain user info from access token!"
              )
            )
            .flatMap(_ => OptionT.none[F, Json])
      }
    } yield user
  }

  /** Using the code that was given by the authentication providers redirect request, get
    * the access token. It returns the raw response only json-decoded into a data
    * structure. If something fails, it is logged ant None is returned
    *
    * See https://openid.net/specs/openid-connect-basic-1_0.html#TokenRequest
    */
  def fetchAccessToken[F[_]: Async](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      cfg: ProviderConfig,
      redirectUri: String,
      code: String
  ): OptionT[F, AccessToken] = {
    import dsl._
    val logger = Logger.log4s[F](log4sLogger)

    val req = POST(
      UrlForm(
        "client_id"     -> cfg.clientId,
        "client_secret" -> cfg.clientSecret,
        "code"          -> code,
        "grant_type"    -> "authorization_code",
        "redirect_uri"  -> redirectUri
      ),
      Uri.unsafeFromString(cfg.tokenUrl.asString),
      Accept(MediaType.application.json)
    )

    OptionT(c.run(req).use {
      case Status.Successful(r) =>
        for {
          token <- r.attemptAs[AccessToken].value
          _ <- token match {
            case Right(t) =>
              logger.trace(s"Got token response: $t")
            case Left(err) =>
              logger.error(err)(s"Error decoding access token: ${err.getMessage}")
          }
        } yield token.toOption
      case r =>
        logger
          .error(s"Error obtaining access token '${r.status.code}' / ${r.as[String]}")
          .map(_ => None)
    })
  }

  /** Fetches user info by using a request against the userinfo endpoint. */
  def fetchFromUserEndpoint[F[_]: Async](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      endpointUrl: LenientUri,
      token: AccessToken
  ): OptionT[F, Json] = {
    import dsl._
    val logger = Logger.log4s[F](log4sLogger)

    val req = GET(
      Uri.unsafeFromString(endpointUrl.asString),
      Authorization(Credentials.Token(AuthScheme.Bearer, token.accessToken)),
      Accept(MediaType.application.json)
    )

    val resp: F[Option[Json]] = c.run(req).use {
      case Status.Successful(r) =>
        for {
          json <- r.attemptAs[Json].value
          _ <- json match {
            case Right(j) =>
              logger.trace(s"Got user info: ${j.noSpaces}")
            case Left(err) =>
              logger.error(err)(s"Error decoding user info response into json!")
          }
        } yield json.toOption
      case r =>
        r.as[String]
          .flatMap(err =>
            logger.error(s"Cannot obtain user info: ${r.status.code} / $err")
          )
          .map(_ => None)
    }
    OptionT(resp)
  }

  private def logRequests[F[_]: Async](c: Client[F]): Client[F] =
    RequestLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => Logger.log4s(log4sLogger).trace(msg))
    )(c)

  private def logResponses[F[_]: Async](c: Client[F]): Client[F] =
    ResponseLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => Logger.log4s(log4sLogger).trace(msg))
    )(c)

}
