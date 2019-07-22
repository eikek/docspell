package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.{Ident, Priority}
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.ResponseGenerator
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.EntityDecoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.multipart.Multipart
import org.log4s._

object UploadRoutes {
  private[this] val logger = getLogger

  def secured[F[_]: Effect](backend: BackendApp[F], cfg: Config, user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "item" =>
        for {
          multipart <- req.as[Multipart[F]]
          updata    <- readMultipart(multipart, logger, Priority.High, cfg.backend.files.validMimeTypes)
          result    <- backend.upload.submit(updata, user.account)
          res  <- Ok(basicResult(result))
        } yield res

    }
  }

  def open[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "item" / Ident(id)=>
        for {
          multipart <- req.as[Multipart[F]]
          updata    <- readMultipart(multipart, logger, Priority.Low, cfg.backend.files.validMimeTypes)
          result    <- backend.upload.submit(updata, id)
          res  <- Ok(basicResult(result))
        } yield res
    }
  }
}
