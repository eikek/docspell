/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{EitherT, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.common._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.Responses
import docspell.store.records.RItem

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.{Authorization, `WWW-Authenticate`}
import org.http4s.multipart.Multipart
import org.log4s.getLogger
import org.typelevel.ci.CIString

object IntegrationEndpointRoutes {
  private[this] val logger = getLogger

  def open[F[_]: Async](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    def validate(req: Request[F], collective: Ident) =
      for {
        _ <- authRequest(req, cfg.integrationEndpoint)
        _ <- checkEnabled(cfg.integrationEndpoint)
        _ <- lookupCollective(collective, backend)
      } yield ()

    HttpRoutes.of {
      case req @ POST -> Root / "item" / Ident(collective) =>
        (for {
          _ <- validate(req, collective)
          res <- EitherT.liftF[F, Response[F], Response[F]](
            uploadFile(collective, backend, cfg, dsl)(req)
          )
        } yield res).fold(identity, identity)

      case req @ GET -> Root / "item" / Ident(collective) =>
        (for {
          _ <- validate(req, collective)
          res <- EitherT.liftF[F, Response[F], Response[F]](Ok(()))
        } yield res).fold(identity, identity)

      case req @ GET -> Root / "checkfile" / Ident(collective) / checksum =>
        (for {
          _ <- validate(req, collective)
          items <- EitherT.liftF[F, Response[F], Vector[RItem]](
            backend.itemSearch.findByFileCollective(checksum, collective)
          )
          resp <-
            EitherT.liftF[F, Response[F], Response[F]](Ok(CheckFileRoutes.convert(items)))
        } yield resp).fold(identity, identity)

    }
  }

  def checkEnabled[F[_]: Async](
      cfg: Config.IntegrationEndpoint
  ): EitherT[F, Response[F], Unit] =
    EitherT.cond[F](cfg.enabled, (), Response.notFound[F])

  def authRequest[F[_]: Async](
      req: Request[F],
      cfg: Config.IntegrationEndpoint
  ): EitherT[F, Response[F], Unit] = {
    val service =
      SourceIpAuth[F](cfg.allowedIps) <+> HeaderAuth(cfg.httpHeader) <+> HttpBasicAuth(
        cfg.httpBasic
      )
    service.run(req).toLeft(())
  }

  def lookupCollective[F[_]: Async](
      coll: Ident,
      backend: BackendApp[F]
  ): EitherT[F, Response[F], Unit] =
    for {
      opt <- EitherT.liftF(backend.collective.find(coll))
      res <- EitherT.cond[F](opt.exists(_.integrationEnabled), (), Response.notFound[F])
    } yield res

  def uploadFile[F[_]: Async](
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
        cfg.integrationEndpoint.sourceName,
        logger,
        cfg.integrationEndpoint.priority,
        cfg.backend.files.validMimeTypes
      )
      account = AccountId(coll, DocspellSystem.user)
      result <- backend.upload.submit(updata, account, true, None)
      res <- Ok(basicResult(result))
    } yield res
  }

  object HeaderAuth {
    def apply[F[_]: Async](cfg: Config.IntegrationEndpoint.HttpHeader): HttpRoutes[F] =
      if (cfg.enabled) checkHeader(cfg)
      else HttpRoutes.empty[F]

    def checkHeader[F[_]: Async](
        cfg: Config.IntegrationEndpoint.HttpHeader
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        val h = req.headers.get(CIString(cfg.headerName))
        if (h.exists(_.head.value == cfg.headerValue)) OptionT.none[F, Response[F]]
        else OptionT.pure(Responses.forbidden[F])
      }
  }

  object SourceIpAuth {
    def apply[F[_]: Async](cfg: Config.IntegrationEndpoint.AllowedIps): HttpRoutes[F] =
      if (cfg.enabled) checkIps(cfg)
      else HttpRoutes.empty[F]

    def checkIps[F[_]: Async](
        cfg: Config.IntegrationEndpoint.AllowedIps
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        //The `req.from' take the X-Forwarded-For header into account,
        //which is not desirable here. The `http-header' auth config
        //can be used to authenticate based on headers.
        val from = req.remote.map(_.host)
        if (from.exists(cfg.containsAddress)) OptionT.none[F, Response[F]]
        else OptionT.pure(Responses.forbidden[F])
      }
  }

  object HttpBasicAuth {
    def apply[F[_]: Async](cfg: Config.IntegrationEndpoint.HttpBasic): HttpRoutes[F] =
      if (cfg.enabled) checkHttpBasic(cfg)
      else HttpRoutes.empty[F]

    def checkHttpBasic[F[_]: Async](
        cfg: Config.IntegrationEndpoint.HttpBasic
    ): HttpRoutes[F] =
      HttpRoutes { req =>
        req.headers.get[Authorization] match {
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
