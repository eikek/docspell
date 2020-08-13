package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restserver.conv.Conversions

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object JobQueueRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "state" =>
        for {
          js <- backend.job.queueState(user.account.collective, 40)
          res = Conversions.mkJobQueueState(js)
          resp <- Ok(res)
        } yield resp

      case POST -> Root / Ident(id) / "cancel" =>
        for {
          result <- backend.job.cancelJob(id, user.account.collective)
          resp   <- Ok(Conversions.basicResult(result))
        } yield resp
    }
  }

}
