package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.Responses

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object FullTextIndexRoutes {

  def secured[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] =
    if (!cfg.fullTextSearch.enabled) notFound[F]
    else {
      val dsl = Http4sDsl[F]
      import dsl._

      HttpRoutes.of { case POST -> Root / "reIndex" =>
        for {
          res  <- backend.fulltext.reindexCollective(user.account).attempt
          resp <- Ok(Conversions.basicResult(res, "Full-text index will be re-created."))
        } yield resp
      }
    }

  def admin[F[_]: Async](cfg: Config, backend: BackendApp[F]): HttpRoutes[F] =
    if (!cfg.fullTextSearch.enabled) notFound[F]
    else {
      val dsl = Http4sDsl[F]
      import dsl._

      HttpRoutes.of { case POST -> Root / "reIndexAll" =>
        for {
          res  <- backend.fulltext.reindexAll.attempt
          resp <- Ok(Conversions.basicResult(res, "Full-text index will be re-created."))
        } yield resp
      }
    }

  private def notFound[F[_]: Async]: HttpRoutes[F] =
    Responses.notFoundRoute[F]
}
