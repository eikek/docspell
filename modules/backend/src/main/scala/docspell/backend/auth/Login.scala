package docspell.backend.auth

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.auth.Login._
import docspell.common._
import docspell.store.Store
import docspell.store.queries.QLogin
import docspell.store.records._

import org.log4s.getLogger
import org.mindrot.jbcrypt.BCrypt
import scodec.bits.ByteVector

trait Login[F[_]] {

  def loginSession(config: Config)(sessionKey: String): F[Result]

  def loginUserPass(config: Config)(up: UserPass): F[Result]

  def loginRememberMe(config: Config)(token: String): F[Result]

  def loginSessionOrRememberMe(
      config: Config
  )(sessionKey: String, rememberId: Option[String]): F[Result]

  def removeRememberToken(token: String): F[Int]
}

object Login {
  private[this] val logger = getLogger

  case class Config(
      serverSecret: ByteVector,
      sessionValid: Duration,
      rememberMe: RememberMe
  )

  case class RememberMe(enabled: Boolean, valid: Duration) {
    val disabled = !enabled
  }

  case class UserPass(user: String, pass: String, rememberMe: Boolean) {
    def hidePass: UserPass =
      if (pass.isEmpty) copy(pass = "<none>")
      else copy(pass = "***")
  }

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
    case object InvalidTime extends Result {
      val toEither = Left("Authentication failed.")
    }

    def ok(session: AuthToken, remember: Option[RememberToken]): Result =
      Ok(session, remember)
    def invalidAuth: Result = InvalidAuth
    def invalidTime: Result = InvalidTime
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, Login[F]] =
    Resource.pure[F, Login[F]](new Login[F] {

      private val logF = Logger.log4s(logger)

      def loginSession(config: Config)(sessionKey: String): F[Result] =
        AuthToken.fromString(sessionKey) match {
          case Right(at) =>
            if (at.sigInvalid(config.serverSecret))
              logF.warn("Cookie signature invalid!") *> Result.invalidAuth.pure[F]
            else if (at.isExpired(config.sessionValid))
              logF.debug("Auth Cookie expired") *> Result.invalidTime.pure[F]
            else Result.ok(at, None).pure[F]
          case Left(_) =>
            Result.invalidAuth.pure[F]
        }

      def loginUserPass(config: Config)(up: UserPass): F[Result] =
        AccountId.parse(up.user) match {
          case Right(acc) =>
            val okResult =
              for {
                _     <- store.transact(RUser.updateLogin(acc))
                token <- AuthToken.user(acc, config.serverSecret)
                rem <- OptionT
                  .whenF(up.rememberMe && config.rememberMe.enabled)(
                    insertRememberToken(store, acc, config)
                  )
                  .value
              } yield Result.ok(token, rem)
            for {
              data <- store.transact(QLogin.findUser(acc))
              _    <- Sync[F].delay(logger.trace(s"Account lookup: $data"))
              res <-
                if (data.exists(check(up.pass))) okResult
                else Result.invalidAuth.pure[F]
            } yield res
          case Left(_) =>
            logF.info(s"User authentication failed for: ${up.hidePass}") *>
              Result.invalidAuth.pure[F]
        }

      def loginRememberMe(config: Config)(token: String): F[Result] = {
        def okResult(acc: AccountId) =
          for {
            _     <- store.transact(RUser.updateLogin(acc))
            token <- AuthToken.user(acc, config.serverSecret)
          } yield Result.ok(token, None)

        def doLogin(rid: Ident) =
          (for {
            now <- OptionT.liftF(Timestamp.current[F])
            minTime = now - config.rememberMe.valid
            data <- OptionT(store.transact(QLogin.findByRememberMe(rid, minTime).value))
            _ <- OptionT.liftF(
              logF.info(s"Account lookup via remember me: $data")
            )
            res <- OptionT.liftF(
              if (checkNoPassword(data))
                logF.info("RememberMe auth successful") *> okResult(data.account)
              else
                logF.warn("RememberMe auth not successfull") *> Result.invalidAuth.pure[F]
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
              else doLogin(rt.rememberId)
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

      private def insertRememberToken(
          store: Store[F],
          acc: AccountId,
          config: Config
      ): F[RememberToken] =
        for {
          rme   <- RRememberMe.generate[F](acc)
          _     <- store.transact(RRememberMe.insert(rme))
          token <- RememberToken.user(rme.id, config.serverSecret)
        } yield token

      private def check(given: String)(data: QLogin.Data): Boolean = {
        val passOk = BCrypt.checkpw(given, data.password.pass)
        checkNoPassword(data) && passOk
      }

      private def checkNoPassword(data: QLogin.Data): Boolean = {
        val collOk = data.collectiveState == CollectiveState.Active ||
          data.collectiveState == CollectiveState.ReadOnly
        val userOk = data.userState == UserState.Active
        collOk && userOk
      }
    })
}
