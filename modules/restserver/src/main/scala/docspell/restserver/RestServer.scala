/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import scala.concurrent.duration._

import cats.effect._
import cats.implicits._
import fs2.Stream
import fs2.concurrent.Topic

import docspell.backend.auth.{AuthToken, ShareToken}
import docspell.backend.msg.Topics
import docspell.common._
import docspell.oidc.CodeFlowRoutes
import docspell.pubsub.naive.NaivePubSub
import docspell.restserver.auth.OpenId
import docspell.restserver.http4s.{EnvMiddleware, InternalHeader}
import docspell.restserver.routes._
import docspell.restserver.webapp._
import docspell.restserver.ws.OutputEvent.KeepAlive
import docspell.restserver.ws.{OutputEvent, WebSocketRoutes}
import docspell.store.Store
import docspell.store.records.RInternalSetting

import org.http4s._
import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.blaze.server.BlazeServerBuilder
import org.http4s.client.Client
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger
import org.http4s.server.websocket.WebSocketBuilder2

object RestServer {

  def serve[F[_]: Async](cfg: Config, pools: Pools): F[ExitCode] =
    for {
      wsTopic <- Topic[F, OutputEvent]
      keepAlive = Stream
        .awakeEvery[F](30.seconds)
        .map(_ => KeepAlive)
        .through(wsTopic.publish)

      server =
        Stream
          .resource(createApp(cfg, pools, wsTopic))
          .flatMap { case (restApp, pubSub, httpClient, setting) =>
            Stream(
              restApp.subscriptions,
              restApp.eventConsume(2),
              BlazeServerBuilder[F]
                .bindHttp(cfg.bind.port, cfg.bind.address)
                .withoutBanner
                .withHttpWebSocketApp(
                  createHttpApp(cfg, setting, httpClient, pubSub, restApp, wsTopic)
                )
                .serve
                .drain
            )
          }

      exit <-
        (server ++ Stream(keepAlive)).parJoinUnbounded.compile.drain.as(ExitCode.Success)
    } yield exit

  def createApp[F[_]: Async](
      cfg: Config,
      pools: Pools,
      wsTopic: Topic[F, OutputEvent]
  ): Resource[
    F,
    (RestApp[F], NaivePubSub[F], Client[F], RInternalSetting)
  ] =
    for {
      httpClient <- BlazeClientBuilder[F].resource
      store <- Store.create[F](
        cfg.backend.jdbc,
        cfg.backend.files.chunkSize,
        pools.connectEC
      )
      setting <- Resource.eval(store.transact(RInternalSetting.create))
      pubSub <- NaivePubSub(
        cfg.pubSubConfig(setting.internalRouteKey),
        store,
        httpClient
      )(Topics.all.map(_.topic))
      restApp <- RestAppImpl.create[F](cfg, store, httpClient, pubSub, wsTopic)
    } yield (restApp, pubSub, httpClient, setting)

  def createHttpApp[F[_]: Async](
      cfg: Config,
      internSettings: RInternalSetting,
      httpClient: Client[F],
      pubSub: NaivePubSub[F],
      restApp: RestApp[F],
      topic: Topic[F, OutputEvent]
  )(
      wsB: WebSocketBuilder2[F]
  ) = {
    val basePath = cfg.baseUrl.path.asString
    val templates = TemplateRoutes[F](cfg)
    val httpApp = Router(
      basePath -> Router(
        "internal" -> InternalHeader(internSettings.internalRouteKey) {
          internalRoutes(pubSub)
        },
        "api/info" -> routes.InfoRoutes(),
        "api/v1/open/" -> openRoutes(cfg, httpClient, restApp),
        "api/v1/sec/" -> Authenticate(restApp.backend.login, cfg.auth) { token =>
          securedRoutes(cfg, restApp, wsB, topic, token)
        },
        "api/v1/admin" -> AdminAuth(cfg.adminEndpoint) {
          adminRoutes(cfg, restApp)
        },
        "api/v1/share" -> ShareAuth(restApp.backend.share, cfg.auth) { token =>
          shareRoutes(cfg, restApp, token)
        },
        "api/doc" -> templates.doc,
        "app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F]),
        "app" -> EnvMiddleware(templates.app),
        "sw.js" -> EnvMiddleware(templates.serviceWorker),
        "" -> redirectTo(basePath + "/app")
      )
    ).orNotFound

    Logger.httpApp(logHeaders = true, logBody = false)(httpApp)
  }

  def internalRoutes[F[_]: Async](pubSub: NaivePubSub[F]): HttpRoutes[F] =
    Router(
      "pubsub" -> pubSub.receiveRoute
    )

  def securedRoutes[F[_]: Async](
      cfg: Config,
      restApp: RestApp[F],
      wsB: WebSocketBuilder2[F],
      topic: Topic[F, OutputEvent],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "ws" -> WebSocketRoutes(token, restApp.backend, topic, wsB),
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
      "items" -> ItemMultiRoutes(cfg, restApp.backend, token),
      "attachment" -> AttachmentRoutes(restApp.backend, cfg, token),
      "attachments" -> AttachmentMultiRoutes(restApp.backend, token),
      "upload" -> UploadRoutes.secured(restApp.backend, cfg, token),
      "checkfile" -> CheckFileRoutes.secured(restApp.backend, token),
      "email/send" -> MailSendRoutes(restApp.backend, token),
      "email/settings" -> MailSettingsRoutes(restApp.backend, token),
      "email/sent" -> SentMailRoutes(restApp.backend, token),
      "share" -> ShareRoutes.manage(restApp.backend, token),
      "usertask/notifydueitems" -> NotifyDueItemsRoutes(cfg, restApp.backend, token),
      "usertask/scanmailbox" -> ScanMailboxRoutes(restApp.backend, token),
      "usertask/periodicquery" -> PeriodicQueryRoutes(cfg, restApp.backend, token),
      "calevent/check" -> CalEventCheckRoutes(),
      "fts" -> FullTextIndexRoutes.secured(cfg, restApp.backend, token),
      "folder" -> FolderRoutes(restApp.backend, token),
      "customfield" -> CustomFieldRoutes(restApp.backend, token),
      "clientSettings" -> ClientSettingsRoutes(restApp.backend, token),
      "notification" -> NotificationRoutes(cfg, restApp.backend, token)
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
      "attachment" -> ShareAttachmentRoutes(restApp.backend, cfg, token),
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
