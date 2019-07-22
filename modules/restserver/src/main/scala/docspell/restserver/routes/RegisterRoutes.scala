package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.ops.OCollective.RegisterData
import docspell.backend.signup.{NewInviteResult, SignupResult}
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.http4s.ResponseGenerator
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

object RegisterRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "register" =>
        for {
          data  <- req.as[Registration]
          res   <- backend.signup.register(cfg.backend.signup)(convert(data))
          resp  <- Ok(convert(res))
        } yield resp

      case req@ POST -> Root / "newinvite" =>
        for {
          data   <- req.as[GenInvite]
          res    <- backend.signup.newInvite(cfg.backend.signup)(data.password)
          resp   <- Ok(convert(res))
        } yield resp
    }
  }

  def convert(r: NewInviteResult): InviteResult = r match {
    case NewInviteResult.Success(id) =>
      InviteResult(true, "New invitation created.", Some(id))
    case NewInviteResult.InvitationDisabled =>
      InviteResult(false, "Signing up is not enabled for invitations.", None)
    case NewInviteResult.PasswordMismatch =>
      InviteResult(false, "Password is invalid.", None)
  }


  def convert(r: SignupResult): BasicResult = r match {
    case SignupResult.CollectiveExists =>
      BasicResult(false, "A collective with this name already exists.")
    case SignupResult.InvalidInvitationKey =>
      BasicResult(false, "Invalid invitation key.")
    case SignupResult.SignupClosed =>
      BasicResult(false, "Sorry, registration is closed.")
    case SignupResult.Failure(ex) =>
      logger.error(ex)("Error signing up")
      BasicResult(false, s"Internal error: ${ex.getMessage}")
    case SignupResult.Success =>
      BasicResult(true, "Signup successful")
  }


  def convert(r: Registration): RegisterData =
    RegisterData(r.collectiveName, r.login, r.password, r.invite)
}
