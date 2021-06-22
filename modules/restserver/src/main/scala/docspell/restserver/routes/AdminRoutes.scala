package docspell.restserver.routes

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.implicits._

import docspell.restserver.Config
import docspell.restserver.http4s.Responses

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.server._
import org.typelevel.ci.CIString

object AdminRoutes {
  private val adminHeader = CIString("Docspell-Admin-Secret")

  def apply[F[_]: Async](cfg: Config.AdminEndpoint)(
      f: HttpRoutes[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = checkSecret[F](cfg)

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware: AuthMiddleware[F, Unit] =
      AuthMiddleware(authUser, onFailure)

    if (cfg.secret.isEmpty) Responses.notFoundRoute[F]
    else middleware(AuthedRoutes(authReq => f.run(authReq.req)))
  }

  private def checkSecret[F[_]: Async](
      cfg: Config.AdminEndpoint
  ): Kleisli[F, Request[F], Either[String, Unit]] =
    Kleisli(req =>
      extractSecret[F](req)
        .filter(compareSecret(cfg.secret))
        .toRight("Secret invalid")
        .map(_ => ())
        .pure[F]
    )

  private def extractSecret[F[_]](req: Request[F]): Option[String] =
    req.headers.get(adminHeader).map(_.head.value)

  private def compareSecret(s1: String)(s2: String): Boolean =
    s1.length > 0 && s1.length == s2.length &&
      s1.zip(s2).forall({ case (a, b) => a == b })
}
