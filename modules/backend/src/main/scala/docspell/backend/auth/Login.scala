/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.auth

import cats.data.{EitherT, NonEmptyList, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.PasswordCrypt
import docspell.backend.auth.Login._
import docspell.common._
import docspell.store.Store
import docspell.store.queries.QLogin
import docspell.store.records._
import docspell.totp.{OnetimePassword, Totp}

import scodec.bits.ByteVector

trait Login[F[_]] {

  def loginExternal(config: Config)(accountId: AccountId): F[Result]

  def loginSession(config: Config)(sessionKey: String): F[Result]

  def loginUserPass(config: Config)(up: UserPass): F[Result]

  def loginSecondFactor(config: Config)(sf: SecondFactor): F[Result]

  def loginRememberMe(config: Config)(token: String): F[Result]

  def loginSessionOrRememberMe(
      config: Config
  )(sessionKey: String, rememberId: Option[String]): F[Result]

  def removeRememberToken(token: String): F[Int]
}

object Login {
  case class Config(
      serverSecret: ByteVector,
      sessionValid: Duration,
      rememberMe: RememberMe,
      onAccountSourceConflict: OnAccountSourceConflict
  )

  sealed trait OnAccountSourceConflict {
    def name: String
  }
  object OnAccountSourceConflict {
    case object Fail extends OnAccountSourceConflict {
      val name = "fail"
    }
    case object Convert extends OnAccountSourceConflict {
      val name = "convert"
    }

    val all: NonEmptyList[OnAccountSourceConflict] =
      NonEmptyList.of(Fail, Convert)

    def fromString(str: String): Either[String, OnAccountSourceConflict] =
      all
        .find(_.name.equalsIgnoreCase(str))
        .toRight(
          s"Invalid on-account-source-conflict value: $str. Use one of ${all.toList.mkString(", ")}"
        )
  }

  case class RememberMe(enabled: Boolean, valid: Duration) {
    val disabled = !enabled
  }

  case class UserPass(user: String, pass: String, rememberMe: Boolean) {
    def hidePass: UserPass =
      if (pass.isEmpty) copy(pass = "<none>")
      else copy(pass = "***")
  }

  final case class SecondFactor(
      token: AuthToken,
      rememberMe: Boolean,
      otp: OnetimePassword
  )

  sealed trait Result {
    def toEither: Either[String, AuthToken]
  }
  object Result {
    case class Ok(session: AuthToken, rememberToken: Option[RememberToken])
        extends Result {
      val toEither = Right(session)
    }
    case object InvalidAuth extends Result {
      val toEither = Left("Authentication failed.")
    }
    case class InvalidAccountSource(account: AccountId) extends Result {
      val toEither = Left(
        s"The account '${account.asString}' already exists from a different source (local vs openid)!"
      )
    }
    case object InvalidTime extends Result {
      val toEither = Left("Authentication failed due expired authenticator.")
    }
    case object InvalidFactor extends Result {
      val toEither = Left("Authentication requires second factor.")
    }

    def ok(session: AuthToken, remember: Option[RememberToken]): Result =
      Ok(session, remember)
    def invalidAuth: Result = InvalidAuth
    def invalidTime: Result = InvalidTime
    def invalidFactor: Result = InvalidFactor
    def invalidAccountSource(account: AccountId): Result = InvalidAccountSource(account)
  }

  def apply[F[_]: Async](store: Store[F], totp: Totp): Resource[F, Login[F]] =
    Resource.pure[F, Login[F]](new Login[F] {

      private val logF = docspell.logging.getLogger[F]

      def loginExternal(config: Config)(accountId: AccountId): F[Result] =
        for {
          data <- store.transact(QLogin.findUser(accountId))
          _ <- logF.trace(s"Account lookup: $data")
          res <- data match {
            case Some(d) if checkNoPassword(d, Set(AccountSource.OpenId)) =>
              doLogin(config, d.account, rememberMe = false)
            case Some(d) if checkNoPassword(d, Set(AccountSource.Local)) =>
              config.onAccountSourceConflict match {
                case OnAccountSourceConflict.Fail =>
                  Result.invalidAccountSource(accountId).pure[F]
                case OnAccountSourceConflict.Convert =>
                  for {
                    _ <- logF.debug(
                      s"Converting account ${d.account.asString} from Local to OpenId!"
                    )
                    _ <- store
                      .transact(
                        RUser.updateSource(
                          d.account.userId,
                          d.account.collectiveId,
                          AccountSource.OpenId
                        )
                      )
                    res <- doLogin(config, d.account, rememberMe = false)
                  } yield res
              }
            case _ =>
              Result.invalidAuth.pure[F]
          }
        } yield res

      def loginSession(config: Config)(sessionKey: String): F[Result] =
        AuthToken.fromString(sessionKey) match {
          case Right(at) =>
            if (at.sigInvalid(config.serverSecret))
              logF.warn("Cookie signature invalid!") *> Result.invalidAuth.pure[F]
            else if (at.isExpired(config.sessionValid))
              logF.debug("Auth Cookie expired") *> Result.invalidTime.pure[F]
            else if (at.requireSecondFactor)
              logF.debug("Auth requires second factor!") *> Result.invalidFactor.pure[F]
            else Result.ok(at, None).pure[F]
          case Left(err) =>
            logF.debug(s"Invalid session token: $err") *> Result.invalidAuth.pure[F]
        }

      def loginUserPass(config: Config)(up: UserPass): F[Result] =
        AccountId.parse(up.user) match {
          case Right(acc) =>
            for {
              data <- store.transact(QLogin.findUser(acc))
              _ <- logF.trace(s"Account lookup: $data")
              res <- data match {
                case Some(d) if check(up.pass)(d, Set(AccountSource.Local)) =>
                  doLogin(config, d.account, up.rememberMe)
                case Some(d) if check(up.pass)(d, Set(AccountSource.OpenId)) =>
                  config.onAccountSourceConflict match {
                    case OnAccountSourceConflict.Fail =>
                      logF.info(
                        s"Fail authentication because of account source mismatch (local vs openid)."
                      ) *>
                        Result.invalidAccountSource(d.account.asAccountId).pure[F]
                    case OnAccountSourceConflict.Convert =>
                      for {
                        _ <- logF.debug(
                          s"Converting account ${d.account.asString} from OpenId to Local!"
                        )
                        _ <- store
                          .transact(
                            RUser.updateSource(
                              d.account.userId,
                              d.account.collectiveId,
                              AccountSource.Local
                            )
                          )
                        res <- doLogin(config, d.account, up.rememberMe)
                      } yield res
                  }
                case _ =>
                  Result.invalidAuth.pure[F]
              }
            } yield res
          case Left(_) =>
            logF.info(s"User authentication failed for: ${up.hidePass}") *>
              Result.invalidAuth.pure[F]
        }

      def loginSecondFactor(config: Config)(sf: SecondFactor): F[Result] = {
        val okResult: F[Result] =
          for {
            _ <- store.transact(RUser.updateLogin(sf.token.account))
            newToken <- AuthToken.user(
              sf.token.account,
              requireSecondFactor = false,
              config.serverSecret,
              None
            )
            rem <- OptionT
              .whenF(sf.rememberMe && config.rememberMe.enabled)(
                insertRememberToken(store, sf.token.account, config)
              )
              .value
          } yield Result.ok(newToken, rem)

        val validateToken: EitherT[F, Result, Unit] = for {
          _ <- EitherT
            .cond[F](sf.token.sigValid(config.serverSecret), (), Result.invalidAuth)
            .leftSemiflatTap(_ =>
              logF.warn("OTP authentication token signature invalid!")
            )
          _ <- EitherT
            .cond[F](sf.token.notExpired(config.sessionValid), (), Result.invalidTime)
            .leftSemiflatTap(_ => logF.info("OTP Token expired."))
          _ <- EitherT
            .cond[F](sf.token.requireSecondFactor, (), Result.invalidAuth)
            .leftSemiflatTap(_ =>
              logF.warn("OTP received for token that is not allowed for 2FA!")
            )
        } yield ()

        (for {
          _ <- validateToken
          key <- EitherT.fromOptionF(
            store.transact(
              RTotp.findEnabledByUserId(sf.token.account.userId, enabled = true)
            ),
            Result.invalidAuth
          )
          now <- EitherT.right[Result](Timestamp.current[F])
          _ <- EitherT.cond[F](
            totp.checkPassword(key.secret, sf.otp, now.value),
            (),
            Result.invalidAuth
          )
        } yield ()).swap.getOrElseF(okResult)
      }

      def loginRememberMe(config: Config)(token: String): F[Result] = {
        def okResult(acc: AccountInfo) =
          for {
            _ <- store.transact(RUser.updateLogin(acc))
            token <- AuthToken.user(
              acc,
              requireSecondFactor = false,
              config.serverSecret,
              None
            )
          } yield Result.ok(token, None)

        def rememberedLogin(rid: Ident) =
          (for {
            now <- OptionT.liftF(Timestamp.current[F])
            minTime = now - config.rememberMe.valid
            data <- OptionT(store.transact(QLogin.findByRememberMe(rid, minTime).value))
            _ <- OptionT.liftF(
              logF.info(s"Account lookup via remember me: $data")
            )
            res <- OptionT.liftF(
              if (checkNoPassword(data, AccountSource.all.toList.toSet))
                logF.info("RememberMe auth successful") *> okResult(data.account)
              else
                logF.warn("RememberMe auth not successful") *> Result.invalidAuth.pure[F]
            )
          } yield res).getOrElseF(
            logF.info("RememberMe not found in database.") *> Result.invalidAuth.pure[F]
          )

        if (config.rememberMe.disabled)
          logF.info(
            "Remember me auth tried, but disabled in config."
          ) *> Result.invalidAuth.pure[F]
        else
          RememberToken.fromString(token) match {
            case Right(rt) =>
              if (rt.sigInvalid(config.serverSecret))
                logF.warn(
                  s"RememberMe cookie signature invalid ($rt)!"
                ) *> Result.invalidAuth
                  .pure[F]
              else if (rt.isExpired(config.rememberMe.valid))
                logF.info(s"RememberMe cookie expired ($rt).") *> Result.invalidTime
                  .pure[F]
              else rememberedLogin(rt.rememberId)
            case Left(err) =>
              logF.info(s"RememberMe cookie was invalid: $err") *> Result.invalidAuth
                .pure[F]
          }
      }

      def loginSessionOrRememberMe(
          config: Config
      )(sessionKey: String, rememberToken: Option[String]): F[Result] =
        loginSession(config)(sessionKey).flatMap {
          case success @ Result.Ok(_, _) => (success: Result).pure[F]
          case fail =>
            rememberToken match {
              case Some(token) =>
                loginRememberMe(config)(token)
              case None =>
                fail.pure[F]
            }
        }

      def removeRememberToken(token: String): F[Int] =
        RememberToken.fromString(token) match {
          case Right(rt) =>
            store.transact(RRememberMe.delete(rt.rememberId))
          case Left(_) =>
            0.pure[F]
        }

      private def doLogin(
          config: Config,
          acc: AccountInfo,
          rememberMe: Boolean
      ): F[Result] =
        for {
          require2FA <- store.transact(RTotp.isEnabled(acc.userId))
          _ <-
            if (require2FA) ().pure[F]
            else store.transact(RUser.updateLogin(acc))
          token <- AuthToken.user(acc, require2FA, config.serverSecret, None)
          rem <- OptionT
            .whenF(!require2FA && rememberMe && config.rememberMe.enabled)(
              insertRememberToken(store, acc, config)
            )
            .value
        } yield Result.ok(token, rem)

      private def insertRememberToken(
          store: Store[F],
          acc: AccountInfo,
          config: Config
      ): F[RememberToken] =
        for {
          rme <- RRememberMe.generate[F](acc.userId)
          _ <- store.transact(RRememberMe.insert(rme))
          token <- RememberToken.user(rme.id, config.serverSecret)
        } yield token

      private def check(
          givenPass: String
      )(data: QLogin.Data, expectedSources: Set[AccountSource]): Boolean = {
        val passOk = PasswordCrypt.check(Password(givenPass), data.password)
        checkNoPassword(data, expectedSources) && passOk
      }

      def checkNoPassword(
          data: QLogin.Data,
          expectedSources: Set[AccountSource]
      ): Boolean = {
        val collOk = data.collectiveState == CollectiveState.Active ||
          data.collectiveState == CollectiveState.ReadOnly
        val userOk =
          data.userState == UserState.Active && expectedSources.contains(data.source)
        collOk && userOk
      }
    })
}
