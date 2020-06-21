package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import cats.data.OptionT
import org.http4s._
//import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

import docspell.common._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restserver.Config
import docspell.restserver.conv.Conversions

object FullTextIndexRoutes {

  def secured[F[_]: Effect](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] =
    if (!cfg.fullTextSearch.enabled) notFound[F]
    else {
      val dsl = Http4sDsl[F]
      import dsl._

      HttpRoutes.of {
        case POST -> Root / "reIndex" =>
          for {
            res <- backend.fulltext.reindexCollective(user.account).attempt
            resp <-
              Ok(Conversions.basicResult(res, "Full-text index will be re-created."))
          } yield resp
      }
    }

  def open[F[_]: Effect](cfg: Config, backend: BackendApp[F]): HttpRoutes[F] =
    if (!cfg.fullTextSearch.enabled) notFound[F]
    else {
      val dsl = Http4sDsl[F]
      import dsl._

      HttpRoutes.of {
        case POST -> Root / "reIndexAll" / Ident(id) =>
          for {
            res <-
              if (id.nonEmpty && id == cfg.fullTextSearch.recreateKey)
                backend.fulltext.reindexAll.attempt
              else Left(new Exception("The provided key is invalid.")).pure[F]
            resp <-
              Ok(Conversions.basicResult(res, "Full-text index will be re-created."))
          } yield resp
      }
    }

  private def notFound[F[_]: Effect]: HttpRoutes[F] =
    HttpRoutes(_ => OptionT.pure(Response.notFound[F]))
}
