/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.auth.{AuthToken, ShareToken}
import docspell.common._
import docspell.oidc.CodeFlowRoutes
import docspell.restserver.auth.OpenId
import docspell.restserver.http4s.EnvMiddleware
import docspell.restserver.routes._
import docspell.restserver.webapp._

import org.http4s._
import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.blaze.server.BlazeServerBuilder
import org.http4s.client.Client
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger

object RestServer {

  def stream[F[_]: Async](cfg: Config, pools: Pools): Stream[F, Nothing] = {

    val templates = TemplateRoutes[F](cfg)
    val app = for {
      restApp <- RestAppImpl.create[F](cfg, pools.connectEC)
      httpClient <- BlazeClientBuilder[F].resource
      httpApp = Router(
        "/api/info" -> routes.InfoRoutes(),
        "/api/v1/open/" -> openRoutes(cfg, httpClient, restApp),
        "/api/v1/sec/" -> Authenticate(restApp.backend.login, cfg.auth) { token =>
          securedRoutes(cfg, restApp, token)
        },
        "/api/v1/admin" -> AdminAuth(cfg.adminEndpoint) {
          adminRoutes(cfg, restApp)
        },
        "/api/v1/share" -> ShareAuth(restApp.backend.share, cfg.auth) { token =>
          shareRoutes(cfg, restApp, token)
        },
        "/api/doc" -> templates.doc,
        "/app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F]),
        "/app" -> EnvMiddleware(templates.app),
        "/sw.js" -> EnvMiddleware(templates.serviceWorker),
        "/" -> redirectTo("/app")
      ).orNotFound

      finalHttpApp = Logger.httpApp(logHeaders = false, logBody = false)(httpApp)

    } yield finalHttpApp

    Stream
      .resource(app)
      .flatMap(httpApp =>
        BlazeServerBuilder[F]
          .bindHttp(cfg.bind.port, cfg.bind.address)
          .withHttpApp(httpApp)
          .withoutBanner
          .serve
      )
  }.drain

  def securedRoutes[F[_]: Async](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth" -> LoginRoutes.session(restApp.backend.login, cfg, token),
      "tag" -> TagRoutes(restApp.backend, token),
      "equipment" -> EquipmentRoutes(restApp.backend, token),
      "organization" -> OrganizationRoutes(restApp.backend, token),
      "person" -> PersonRoutes(restApp.backend, token),
      "source" -> SourceRoutes(restApp.backend, token),
      "user/otp" -> TotpRoutes(restApp.backend, cfg, token),
      "user" -> UserRoutes(restApp.backend, token),
      "collective" -> CollectiveRoutes(restApp.backend, token),
      "queue" -> JobQueueRoutes(restApp.backend, token),
      "item" -> ItemRoutes(cfg, restApp.backend, token),
      "items" -> ItemMultiRoutes(restApp.backend, token),
      "attachment" -> AttachmentRoutes(restApp.backend, token),
      "attachments" -> AttachmentMultiRoutes(restApp.backend, token),
      "upload" -> UploadRoutes.secured(restApp.backend, cfg, token),
      "checkfile" -> CheckFileRoutes.secured(restApp.backend, token),
      "email/send" -> MailSendRoutes(restApp.backend, token),
      "email/settings" -> MailSettingsRoutes(restApp.backend, token),
      "email/sent" -> SentMailRoutes(restApp.backend, token),
      "share" -> ShareRoutes.manage(restApp.backend, token),
      "usertask/notifydueitems" -> NotifyDueItemsRoutes(cfg, restApp.backend, token),
      "usertask/scanmailbox" -> ScanMailboxRoutes(restApp.backend, token),
      "calevent/check" -> CalEventCheckRoutes(),
      "fts" -> FullTextIndexRoutes.secured(cfg, restApp.backend, token),
      "folder" -> FolderRoutes(restApp.backend, token),
      "customfield" -> CustomFieldRoutes(restApp.backend, token),
      "clientSettings" -> ClientSettingsRoutes(restApp.backend, token)
    )

  def openRoutes[F[_]: Async](
      cfg: Config,
      client: Client[F],
      restApp: RestApp[F]
  ): HttpRoutes[F] =
    Router(
      "auth/openid" -> CodeFlowRoutes(
        cfg.openIdEnabled,
        OpenId.handle[F](restApp.backend, cfg),
        OpenId.codeFlowConfig(cfg),
        client
      ),
      "auth" -> LoginRoutes.login(restApp.backend.login, cfg),
      "signup" -> RegisterRoutes(restApp.backend, cfg),
      "upload" -> UploadRoutes.open(restApp.backend, cfg),
      "checkfile" -> CheckFileRoutes.open(restApp.backend),
      "integration" -> IntegrationEndpointRoutes.open(restApp.backend, cfg),
      "share" -> ShareRoutes.verify(restApp.backend, cfg)
    )

  def adminRoutes[F[_]: Async](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "fts" -> FullTextIndexRoutes.admin(cfg, restApp.backend),
      "user/otp" -> TotpRoutes.admin(restApp.backend),
      "user" -> UserRoutes.admin(restApp.backend),
      "info" -> InfoRoutes.admin(cfg),
      "attachments" -> AttachmentRoutes.admin(restApp.backend)
    )

  def shareRoutes[F[_]: Async](
      cfg: Config,
      restApp: RestApp[F],
      token: ShareToken
  ): HttpRoutes[F] =
    Router(
      "search" -> ShareSearchRoutes(restApp.backend, cfg, token),
      "attachment" -> ShareAttachmentRoutes(restApp.backend, token),
      "item" -> ShareItemRoutes(restApp.backend, token)
    )

  def redirectTo[F[_]: Async](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      Response[F](
        Status.SeeOther,
        body = Stream.empty,
        headers = Headers(Location(Uri(path = Uri.Path.unsafeFromString(path))))
      ).pure[F]
    }
  }
}
