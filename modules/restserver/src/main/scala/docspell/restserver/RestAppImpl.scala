/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect._
import fs2.Stream
import fs2.concurrent.Topic

import docspell.backend.BackendApp
import docspell.backend.auth.{AuthToken, ShareToken}
import docspell.common.Pools
import docspell.config.FtsType
import docspell.ftsclient.FtsClient
import docspell.ftspsql.PsqlFtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.notification.api.NotificationModule
import docspell.notification.impl.NotificationModuleImpl
import docspell.oidc.CodeFlowRoutes
import docspell.pubsub.api.{PubSub, PubSubT}
import docspell.restserver.auth.OpenId
import docspell.restserver.http4s.EnvMiddleware
import docspell.restserver.routes._
import docspell.restserver.webapp.{TemplateRoutes, Templates, WebjarRoutes}
import docspell.restserver.ws.{OutputEvent, WebSocketRoutes}
import docspell.scheduler.impl.JobStoreModuleBuilder
import docspell.store.Store

import emil.javamail.JavaMailEmil
import org.http4s.HttpRoutes
import org.http4s.client.Client
import org.http4s.server.Router
import org.http4s.server.websocket.WebSocketBuilder2

final class RestAppImpl[F[_]: Async](
    val config: Config,
    val backend: BackendApp[F],
    httpClient: Client[F],
    notificationMod: NotificationModule[F],
    wsTopic: Topic[F, OutputEvent],
    pubSub: PubSubT[F]
) extends RestApp[F] {

  def eventConsume(maxConcurrent: Int): Stream[F, Nothing] =
    notificationMod.consumeAllEvents(maxConcurrent)

  def subscriptions: Stream[F, Nothing] =
    Subscriptions[F](wsTopic, pubSub)

  def routes(wsb: WebSocketBuilder2[F]): HttpRoutes[F] =
    createHttpApp(wsb)

  val templates = TemplateRoutes[F](config, Templates[F])

  def createHttpApp(
      wsB: WebSocketBuilder2[F]
  ) =
    Router(
      "/api/info" -> InfoRoutes(),
      "/api/v1/open/" -> openRoutes(httpClient),
      "/api/v1/sec/" -> Authenticate(backend.login, config.auth) { token =>
        securedRoutes(wsB, token)
      },
      "/api/v1/admin" -> AdminAuth(config.adminEndpoint) {
        adminRoutes
      },
      "/api/v1/share" -> ShareAuth(backend.share, config.auth) { token =>
        shareRoutes(token)
      },
      "/api/doc" -> templates.doc,
      "/app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F]),
      "/app" -> EnvMiddleware(templates.app),
      "/sw.js" -> EnvMiddleware(templates.serviceWorker)
    )

  def adminRoutes: HttpRoutes[F] =
    Router(
      "fts" -> FullTextIndexRoutes.admin(config, backend),
      "user/otp" -> TotpRoutes.admin(backend),
      "user" -> UserRoutes.admin(backend),
      "info" -> InfoRoutes.admin(config),
      "attachments" -> AttachmentRoutes.admin(backend),
      "files" -> FileRepositoryRoutes.admin(backend)
    )

  def shareRoutes(
      token: ShareToken
  ): HttpRoutes[F] =
    Router(
      "search" -> ShareSearchRoutes(backend, config, token),
      "attachment" -> ShareAttachmentRoutes(backend, token),
      "item" -> ShareItemRoutes(backend, token),
      "clientSettings" -> ClientSettingsRoutes.share(backend, token),
      "downloadAll" -> DownloadAllRoutes.forShare(config.downloadAll, backend, token)
    )

  def openRoutes(
      client: Client[F]
  ): HttpRoutes[F] =
    Router(
      "auth/openid" -> CodeFlowRoutes(
        config.openIdEnabled,
        OpenId.handle[F](backend, config),
        OpenId.codeFlowConfig(config),
        client
      ),
      "auth" -> LoginRoutes.login(backend.login, config),
      "signup" -> RegisterRoutes(backend, config),
      "upload" -> UploadRoutes.open(backend, config),
      "checkfile" -> CheckFileRoutes.open(backend),
      "integration" -> IntegrationEndpointRoutes.open(backend, config),
      "share" -> ShareRoutes.verify(backend, config)
    )

  def securedRoutes(
      wsB: WebSocketBuilder2[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "ws" -> WebSocketRoutes(token, backend, wsTopic, wsB),
      "auth" -> LoginRoutes.session(backend.login, config, token),
      "tag" -> TagRoutes(backend, token),
      "equipment" -> EquipmentRoutes(backend, token),
      "organization" -> OrganizationRoutes(backend, token),
      "person" -> PersonRoutes(backend, token),
      "source" -> SourceRoutes(backend, token),
      "user/otp" -> TotpRoutes(backend, config, token),
      "user" -> UserRoutes(backend, token),
      "collective" -> CollectiveRoutes(backend, token),
      "queue" -> JobQueueRoutes(backend, token),
      "item" -> ItemRoutes(config, backend, token),
      "items" -> ItemMultiRoutes(config, backend, token),
      "itemlink" -> ItemLinkRoutes(token.account, backend.itemLink),
      "attachment" -> AttachmentRoutes(backend, token),
      "attachments" -> AttachmentMultiRoutes(backend, token),
      "upload" -> UploadRoutes.secured(backend, config, token),
      "checkfile" -> CheckFileRoutes.secured(backend, token),
      "email/send" -> MailSendRoutes(backend, token),
      "email/settings" -> MailSettingsRoutes(backend, token),
      "email/sent" -> SentMailRoutes(backend, token),
      "share" -> ShareRoutes.manage(backend, token),
      "usertask/notifydueitems" -> NotifyDueItemsRoutes(config, backend, token),
      "usertask/scanmailbox" -> ScanMailboxRoutes(backend, token),
      "usertask/periodicquery" -> PeriodicQueryRoutes(config, backend, token),
      "calevent/check" -> CalEventCheckRoutes(),
      "fts" -> FullTextIndexRoutes.secured(config, backend, token),
      "folder" -> FolderRoutes(backend, token),
      "customfield" -> CustomFieldRoutes(backend, token),
      "clientSettings" -> ClientSettingsRoutes(backend, token),
      "notification" -> NotificationRoutes(config, backend, token),
      "querybookmark" -> BookmarkRoutes(backend, token),
      "downloadAll" -> DownloadAllRoutes(config.downloadAll, backend, token)
    )

}

object RestAppImpl {

  def create[F[_]: Async](
      cfg: Config,
      pools: Pools,
      store: Store[F],
      httpClient: Client[F],
      pubSub: PubSub[F],
      wsTopic: Topic[F, OutputEvent]
  ): Resource[F, RestApp[F]] = {
    val logger = docspell.logging.getLogger[F](s"restserver-${cfg.appId.id}")

    for {
      ftsClient <- createFtsClient(cfg, pools, store, httpClient)
      pubSubT = PubSubT(pubSub, logger)
      javaEmil = JavaMailEmil(cfg.backend.mailSettings)
      notificationMod <- Resource.eval(
        NotificationModuleImpl[F](store, javaEmil, httpClient, 200)
      )
      schedulerMod = JobStoreModuleBuilder(store)
        .withPubsub(pubSubT)
        .withEventSink(notificationMod)
        .build
      backend <- BackendApp
        .create[F](store, javaEmil, ftsClient, pubSubT, schedulerMod, notificationMod)

      app = new RestAppImpl[F](
        cfg,
        backend,
        httpClient,
        notificationMod,
        wsTopic,
        pubSubT
      )
    } yield app
  }

  private def createFtsClient[F[_]: Async](
      cfg: Config,
      pools: Pools,
      store: Store[F],
      client: Client[F]
  ): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled)
      cfg.fullTextSearch.backend match {
        case FtsType.Solr =>
          SolrFtsClient(cfg.fullTextSearch.solr, client)

        case FtsType.PostgreSQL =>
          val psqlCfg = cfg.fullTextSearch.postgresql.toPsqlConfig(cfg.backend.jdbc)
          if (cfg.fullTextSearch.postgresql.useDefaultConnection)
            Resource.pure[F, FtsClient[F]](
              new PsqlFtsClient[F](psqlCfg, store.transactor)
            )
          else
            PsqlFtsClient(psqlCfg, pools.connectEC)
      }
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])

}
