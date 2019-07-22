package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.ResponseGenerator
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object UserRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config, user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "changePassword" =>
        for {
          data   <- req.as[PasswordChange]
          res    <- backend.collective.changePassword(user.account, data.currentPassword, data.newPassword)
          resp   <- Ok(basicResult(res))
        } yield resp

      case GET -> Root =>
        for {
          all  <- backend.collective.listUser(user.account.collective)
          res  <- Ok(UserList(all.map(mkUser).toList))
        } yield res

      case req @ POST -> Root =>
        for {
          data  <- req.as[User]
          nuser <- newUser(data, user.account.collective)
          added <- backend.collective.add(nuser)
          resp  <- Ok(basicResult(added, "User created."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data   <- req.as[User]
          nuser  = changeUser(data, user.account.collective)
          update <- backend.collective.update(nuser)
          resp   <- Ok(basicResult(update, "User updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          ar  <- backend.collective.deleteUser(id, user.account.collective)
          resp <- Ok(basicResult(ar, "User deleted."))
        } yield resp
    }
  }

}
