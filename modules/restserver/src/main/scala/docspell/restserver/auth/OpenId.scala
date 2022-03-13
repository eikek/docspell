/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.auth

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.Login
import docspell.backend.signup.{ExternalAccount, SignupResult}
import docspell.common._
import docspell.oidc.{CodeFlowConfig, OnUserInfo, UserInfoDecoder}
import docspell.restserver.Config
import docspell.restserver.auth.OpenId.UserInfo.{ExtractResult, Extractor}
import docspell.restserver.http4s.ClientRequestInfo

import io.circe.Json
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.{Response, Uri}

object OpenId {

  def codeFlowConfig[F[_]](config: Config): CodeFlowConfig[F] =
    CodeFlowConfig(
      req =>
        ClientRequestInfo
          .getBaseUrl(config, req) / "api" / "v1" / "open" / "auth" / "openid",
      id =>
        config.openid.filter(_.enabled).find(_.provider.providerId == id).map(_.provider)
    )

  def handle[F[_]: Async](backend: BackendApp[F], config: Config): OnUserInfo[F] =
    OnUserInfo { (req, provider, userInfo) =>
      val logger = docspell.logging.getLogger[F]
      val dsl = new Http4sDsl[F] {}
      import dsl._
      val baseUrl = ClientRequestInfo.getBaseUrl(config, req)
      val uri = baseUrl.withQuery("openid", "1") / "app" / "login"
      val location = Location(Uri.unsafeFromString(uri.asString))
      val cfg = config.openid
        .find(_.provider.providerId == provider.providerId)
        .getOrElse(sys.error("No config found, but provider which is impossible :)"))

      userInfo match {
        case Some(userJson) =>
          val extractColl = cfg.collectiveKey.find(userJson)

          extractColl match {
            case ExtractResult.Failure(message) =>
              logger.warn(
                s"Can't retrieve user data using collective-key=${cfg.collectiveKey.asString}: $message"
              ) *>
                SeeOther(location)

            case ExtractResult.Account(accountId) =>
              signUpAndLogin[F](backend)(config, accountId, location, baseUrl)

            case ExtractResult.Identifier(coll) =>
              Extractor.Lookup(cfg.userKey).find(userJson) match {
                case ExtractResult.Failure(message) =>
                  logger.warn(
                    s"Can't retrieve user data using user-key=${cfg.userKey}: $message"
                  ) *>
                    SeeOther(location)

                case ExtractResult.Identifier(name) =>
                  signUpAndLogin[F](backend)(
                    config,
                    AccountId(coll, name),
                    location,
                    baseUrl
                  )

                case ExtractResult.Account(accountId) =>
                  signUpAndLogin[F](backend)(
                    config,
                    accountId.copy(collective = coll),
                    location,
                    baseUrl
                  )
              }
          }

        case None =>
          TemporaryRedirect(location)
      }
    }

  def signUpAndLogin[F[_]: Async](
      backend: BackendApp[F]
  )(
      cfg: Config,
      accountId: AccountId,
      location: Location,
      baseUrl: LenientUri
  ): F[Response[F]] = {
    val logger = docspell.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    for {
      setup <- backend.signup.setupExternal(cfg.backend.signup)(
        ExternalAccount(accountId)
      )
      res <- setup match {
        case SignupResult.Failure(ex) =>
          logger.error(ex)(s"Error when creating external account!") *>
            SeeOther(location)

        case SignupResult.SignupClosed =>
          logger.error(s"External accounts don't work when signup is closed!") *>
            SeeOther(location)

        case SignupResult.CollectiveExists =>
          logger.error(
            s"Error when creating external accounts! Collective exists error reported. This is a bug!"
          ) *>
            SeeOther(location)

        case SignupResult.InvalidInvitationKey =>
          logger.error(
            s"Error when creating external accounts! Invalid invitation key reported. This is a bug!"
          ) *>
            SeeOther(location)

        case SignupResult.Success =>
          loginAndVerify(backend, cfg)(accountId, location, baseUrl)
      }
    } yield res
  }

  def loginAndVerify[F[_]: Async](backend: BackendApp[F], config: Config)(
      accountId: AccountId,
      location: Location,
      baseUrl: LenientUri
  ): F[Response[F]] = {
    val logger = docspell.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    for {
      login <- backend.login.loginExternal(config.auth)(accountId)
      resp <- login match {
        case Login.Result.Ok(session, _) =>
          val loc =
            if (session.requireSecondFactor)
              location.copy(uri =
                location.uri
                  .withQueryParam("openid", "2")
                  .withQueryParam("auth", session.asString)
              )
            else location
          SeeOther(loc)
            .map(_.addCookie(CookieData(session).asCookie(baseUrl)))

        case failed =>
          logger.error(s"External login failed: $failed") *>
            SeeOther(location)
      }
    } yield resp
  }

  object UserInfo {

    sealed trait Extractor {
      def find(json: Json): ExtractResult
      def asString: String
    }
    object Extractor {
      final case class Fixed(value: String) extends Extractor {
        def find(json: Json): ExtractResult =
          UserInfoDecoder
            .normalizeUid(value)
            .fold(err => ExtractResult.Failure(err), ExtractResult.Identifier)

        val asString = s"fixed:$value"
      }

      final case class Lookup(value: String) extends Extractor {
        def find(json: Json): ExtractResult =
          UserInfoDecoder
            .findSomeId(value)
            .decodeJson(json)
            .fold(
              err => ExtractResult.Failure(err.getMessage()),
              ExtractResult.Identifier
            )

        val asString = s"lookup:$value"
      }

      final case class AccountLookup(value: String) extends Extractor {
        def find(json: Json): ExtractResult =
          UserInfoDecoder
            .findSomeString(value)
            .emap(AccountId.parse)
            .decodeJson(json)
            .fold(df => ExtractResult.Failure(df.getMessage()), ExtractResult.Account)

        def asString = s"account:$value"
      }

      def fromString(str: String): Either[String, Extractor] =
        str.span(_ != ':') match {
          case (_, "") =>
            Left(s"Invalid extractor, there is no value: $str")
          case (_, value) if value == ":" =>
            Left(s"Invalid extractor, there is no value: $str")

          case (prefix, value) =>
            prefix.toLowerCase match {
              case "fixed" =>
                Right(Fixed(value.drop(1)))
              case "lookup" =>
                Right(Lookup(value.drop(1)))
              case "account" =>
                Right(AccountLookup(value.drop(1)))
              case _ =>
                Left(s"Invalid prefix: $prefix")
            }
        }
    }

    sealed trait ExtractResult
    object ExtractResult {
      final case class Identifier(name: Ident) extends ExtractResult
      final case class Account(accountId: AccountId) extends ExtractResult
      final case class Failure(message: String) extends ExtractResult
    }
  }
}
