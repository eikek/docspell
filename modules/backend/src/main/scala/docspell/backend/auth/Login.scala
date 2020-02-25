package docspell.backend.auth

import cats.effect._
import cats.implicits._
import Login._
import docspell.common._
import docspell.store.Store
import docspell.store.queries.QLogin
import docspell.store.records.RUser
import org.mindrot.jbcrypt.BCrypt
import scodec.bits.ByteVector
import org.log4s._

trait Login[F[_]] {

  def loginSession(config: Config)(sessionKey: String): F[Result]

  def loginUserPass(config: Config)(up: UserPass): F[Result]

}

object Login {
  private[this] val logger = getLogger

  case class Config(serverSecret: ByteVector, sessionValid: Duration)

  case class UserPass(user: String, pass: String) {
    def hidePass: UserPass =
      if (pass.isEmpty) copy(pass = "<none>")
      else copy(pass = "***")
  }

  sealed trait Result {
    def toEither: Either[String, AuthToken]
  }
  object Result {
    case class Ok(session: AuthToken) extends Result {
      val toEither = Right(session)
    }
    case object InvalidAuth extends Result {
      val toEither = Left("Authentication failed.")
    }
    case object InvalidTime extends Result {
      val toEither = Left("Authentication failed.")
    }

    def ok(session: AuthToken): Result = Ok(session)
    def invalidAuth: Result            = InvalidAuth
    def invalidTime: Result            = InvalidTime
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, Login[F]] =
    Resource.pure[F, Login[F]](new Login[F] {

      def loginSession(config: Config)(sessionKey: String): F[Result] =
        AuthToken.fromString(sessionKey) match {
          case Right(at) =>
            if (at.sigInvalid(config.serverSecret)) Result.invalidAuth.pure[F]
            else if (at.isExpired(config.sessionValid)) Result.invalidTime.pure[F]
            else Result.ok(at).pure[F]
          case Left(_) =>
            Result.invalidAuth.pure[F]
        }

      def loginUserPass(config: Config)(up: UserPass): F[Result] =
        AccountId.parse(up.user) match {
          case Right(acc) =>
            val okResult =
              store.transact(RUser.updateLogin(acc)) *>
                AuthToken.user(acc, config.serverSecret).map(Result.ok)
            for {
              data <- store.transact(QLogin.findUser(acc))
              _    <- Sync[F].delay(logger.trace(s"Account lookup: $data"))
              res <- if (data.exists(check(up.pass))) okResult
              else Result.invalidAuth.pure[F]
            } yield res
          case Left(_) =>
            Result.invalidAuth.pure[F]
        }

      private def check(given: String)(data: QLogin.Data): Boolean = {
        val collOk = data.collectiveState == CollectiveState.Active ||
          data.collectiveState == CollectiveState.ReadOnly
        val userOk = data.userState == UserState.Active
        val passOk = BCrypt.checkpw(given, data.password.pass)
        collOk && userOk && passOk
      }
    })
}
