package docspell.restserver.routes

import cats.data.{EitherT, OptionT}
import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.common._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.Responses
import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.EntityDecoder._
import org.http4s.headers.{Authorization, `WWW-Authenticate`}
import org.http4s.multipart.Multipart
import org.http4s.util.CaseInsensitiveString
import org.log4s.getLogger

object IntegrationEndpointRoutes {
  private[this] val logger = getLogger

  def open[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "item" / Ident(collective) =>
        (for {
          _ <- checkEnabled(cfg.integrationEndpoint)
          _ <- authRequest(req, cfg.integrationEndpoint)
          _ <- lookupCollective(collective, backend)
          res <- EitherT.liftF[F, Response[F], Response[F]](
            uploadFile(collective, backend, cfg, dsl)(req)
          )
        } yield res).fold(identity, identity)
    }
  }

  def checkEnabled[F[_]: Effect](
      cfg: Config.IntegrationEndpoint
  ): EitherT[F, Response[F], Unit] =
    EitherT.cond[F](cfg.enabled, (), Response.notFound[F])

  def authRequest[F[_]: Effect](
      req: Request[F],
      cfg: Config.IntegrationEndpoint
  ): EitherT[F, Response[F], Unit] = {
    val service =
      SourceIpAuth[F](cfg.allowedIps) <+> HeaderAuth(cfg.httpHeader) <+> HttpBasicAuth(
        cfg.httpBasic
      )
    service.run(req).toLeft(())
  }

  def lookupCollective[F[_]: Effect](
      coll: Ident,
      backend: BackendApp[F]
  ): EitherT[F, Response[F], Unit] =
    for {
      opt <- EitherT.liftF(backend.collective.find(coll))
      res <- EitherT.cond[F](opt.exists(_.integrationEnabled), (), Response.notFound[F])
    } yield res

  def uploadFile[F[_]: Effect](
      coll: Ident,
      backend: BackendApp[F],
      cfg: Config,
      dsl: Http4sDsl[F]
  )(
      req: Request[F]
  ): F[Response[F]] = {
    import dsl._
    for {
      multipart <- req.as[Multipart[F]]
      updata <- readMultipart(
        multipart,
        logger,
        cfg.integrationEndpoint.priority,
        cfg.backend.files.validMimeTypes
      )
      account = AccountId(coll, Ident.unsafe("docspell-system"))
      result <- backend.upload.submit(updata, account, true, None)
      res    <- Ok(basicResult(result))
    } yield res
  }

  object HeaderAuth {
    def apply[F[_]: Effect](cfg: Config.IntegrationEndpoint.HttpHeader): HttpRoutes[F] =
      if (cfg.enabled) checkHeader(cfg)
      else HttpRoutes.empty[F]

    def checkHeader[F[_]: Effect](
        cfg: Config.IntegrationEndpoint.HttpHeader
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        val h = req.headers.find(_.name == CaseInsensitiveString(cfg.headerName))
        if (h.exists(_.value == cfg.headerValue)) OptionT.none[F, Response[F]]
        else OptionT.pure(Responses.forbidden[F])
      }
  }

  object SourceIpAuth {
    def apply[F[_]: Effect](cfg: Config.IntegrationEndpoint.AllowedIps): HttpRoutes[F] =
      if (cfg.enabled) checkIps(cfg)
      else HttpRoutes.empty[F]

    def checkIps[F[_]: Effect](
        cfg: Config.IntegrationEndpoint.AllowedIps
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        //The `req.from' take the X-Forwarded-For header into account,
        //which is not desirable here. The `http-header' auth config
        //can be used to authenticate based on headers.
        val from = req.remote.flatMap(remote => Option(remote.getAddress))
        if (from.exists(cfg.containsAddress)) OptionT.none[F, Response[F]]
        else OptionT.pure(Responses.forbidden[F])
      }
  }

  object HttpBasicAuth {
    def apply[F[_]: Effect](cfg: Config.IntegrationEndpoint.HttpBasic): HttpRoutes[F] =
      if (cfg.enabled) checkHttpBasic(cfg)
      else HttpRoutes.empty[F]

    def checkHttpBasic[F[_]: Effect](
        cfg: Config.IntegrationEndpoint.HttpBasic
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        req.headers.get(Authorization) match {
          case Some(auth) =>
            auth.credentials match {
              case BasicCredentials(user, pass)
                  if user == cfg.user && pass == cfg.password =>
                OptionT.none[F, Response[F]]
              case _ =>
                OptionT.pure(Responses.forbidden[F])
            }
          case None =>
            OptionT.pure(
              Responses
                .unauthorized[F]
                .withHeaders(
                  `WWW-Authenticate`(Challenge("Basic", cfg.realm))
                )
            )
        }
      }
  }
}
