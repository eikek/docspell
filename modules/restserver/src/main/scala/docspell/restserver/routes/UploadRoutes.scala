package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.ResponseGenerator

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.multipart.Multipart
import org.log4s._

object UploadRoutes {
  private[this] val logger = getLogger

  def secured[F[_]: Effect](
      backend: BackendApp[F],
      cfg: Config,
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    val submitting = submitFiles[F](backend, cfg, Right(user.account)) _

    HttpRoutes.of {
      case req @ POST -> Root / "item" =>
        submitting(req, None, Priority.High, dsl)

      case req @ POST -> Root / "item" / Ident(itemId) =>
        submitting(req, Some(itemId), Priority.High, dsl)
    }
  }

  def open[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "item" / Ident(srcId) =>
        (for {
          _ <- OptionT(backend.collective.findEnabledSource(srcId))
          res <- OptionT.liftF(
            submitFiles(backend, cfg, Left(srcId))(req, None, Priority.Low, dsl)
          )
        } yield res).getOrElseF(NotFound())

      case req @ POST -> Root / "item" / Ident(itemId) / Ident(srcId) =>
        (for {
          _ <- OptionT(backend.collective.findEnabledSource(srcId))
          res <- OptionT.liftF(
            submitFiles(backend, cfg, Left(srcId))(req, Some(itemId), Priority.Low, dsl)
          )
        } yield res).getOrElseF(NotFound())
    }
  }

  private def submitFiles[F[_]: Effect](
      backend: BackendApp[F],
      cfg: Config,
      accOrSrc: Either[Ident, AccountId]
  )(
      req: Request[F],
      itemId: Option[Ident],
      prio: Priority,
      dsl: Http4sDsl[F]
  ): F[Response[F]] = {
    import dsl._

    for {
      multipart <- req.as[Multipart[F]]
      updata <- readMultipart(
        multipart,
        logger,
        prio,
        cfg.backend.files.validMimeTypes
      )
      result <- backend.upload.submitEither(updata, accOrSrc, true, itemId)
      res    <- Ok(basicResult(result))
    } yield res
  }
}
