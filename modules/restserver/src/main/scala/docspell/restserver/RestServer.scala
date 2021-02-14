package docspell.restserver

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restserver.http4s.EnvMiddleware
import docspell.restserver.routes._
import docspell.restserver.webapp._

import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.server.middleware.Logger

object RestServer {

  def stream[F[_]: ConcurrentEffect](
      cfg: Config,
      pools: Pools
  )(implicit T: Timer[F], CS: ContextShift[F]): Stream[F, Nothing] = {

    val templates = TemplateRoutes[F](pools.blocker, cfg)
    val app = for {
      restApp <-
        RestAppImpl
          .create[F](cfg, pools.connectEC, pools.httpClientEC, pools.blocker)
      httpApp = Router(
        "/api/info"     -> routes.InfoRoutes(),
        "/api/v1/open/" -> openRoutes(cfg, restApp),
        "/api/v1/sec/" -> Authenticate(restApp.backend.login, cfg.auth) { token =>
          securedRoutes(cfg, pools, restApp, token)
        },
        "/api/v1/admin" -> AdminRoutes(cfg.adminEndpoint) {
          adminRoutes(cfg, restApp)
        },
        "/api/doc"    -> templates.doc,
        "/app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F](pools.blocker)),
        "/app"        -> EnvMiddleware(templates.app),
        "/sw.js"      -> EnvMiddleware(templates.serviceWorker),
        "/"           -> redirectTo("/app")
      ).orNotFound

      finalHttpApp = Logger.httpApp(logHeaders = false, logBody = false)(httpApp)

    } yield finalHttpApp

    Stream
      .resource(app)
      .flatMap(httpApp =>
        BlazeServerBuilder[F](pools.restEC)
          .bindHttp(cfg.bind.port, cfg.bind.address)
          .withHttpApp(httpApp)
          .withoutBanner
          .serve
      )
  }.drain

  def securedRoutes[F[_]: Effect: ContextShift](
      cfg: Config,
      pools: Pools,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth"                    -> LoginRoutes.session(restApp.backend.login, cfg, token),
      "tag"                     -> TagRoutes(restApp.backend, token),
      "equipment"               -> EquipmentRoutes(restApp.backend, token),
      "organization"            -> OrganizationRoutes(restApp.backend, token),
      "person"                  -> PersonRoutes(restApp.backend, token),
      "source"                  -> SourceRoutes(restApp.backend, token),
      "user"                    -> UserRoutes(restApp.backend, token),
      "collective"              -> CollectiveRoutes(restApp.backend, token),
      "queue"                   -> JobQueueRoutes(restApp.backend, token),
      "item"                    -> ItemRoutes(cfg, pools.blocker, restApp.backend, token),
      "items"                   -> ItemMultiRoutes(restApp.backend, token),
      "attachment"              -> AttachmentRoutes(pools.blocker, restApp.backend, token),
      "upload"                  -> UploadRoutes.secured(restApp.backend, cfg, token),
      "checkfile"               -> CheckFileRoutes.secured(restApp.backend, token),
      "email/send"              -> MailSendRoutes(restApp.backend, token),
      "email/settings"          -> MailSettingsRoutes(restApp.backend, token),
      "email/sent"              -> SentMailRoutes(restApp.backend, token),
      "usertask/notifydueitems" -> NotifyDueItemsRoutes(cfg, restApp.backend, token),
      "usertask/scanmailbox"    -> ScanMailboxRoutes(restApp.backend, token),
      "calevent/check"          -> CalEventCheckRoutes(),
      "fts"                     -> FullTextIndexRoutes.secured(cfg, restApp.backend, token),
      "folder"                  -> FolderRoutes(restApp.backend, token),
      "customfield"             -> CustomFieldRoutes(restApp.backend, token)
    )

  def openRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "auth"        -> LoginRoutes.login(restApp.backend.login, cfg),
      "signup"      -> RegisterRoutes(restApp.backend, cfg),
      "upload"      -> UploadRoutes.open(restApp.backend, cfg),
      "checkfile"   -> CheckFileRoutes.open(restApp.backend),
      "integration" -> IntegrationEndpointRoutes.open(restApp.backend, cfg)
    )

  def adminRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "fts"  -> FullTextIndexRoutes.admin(cfg, restApp.backend),
      "user" -> UserRoutes.admin(restApp.backend),
      "info" -> InfoRoutes.admin(cfg)
    )

  def redirectTo[F[_]: Effect](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      Response[F](
        Status.SeeOther,
        body = Stream.empty,
        headers = Headers.of(Location(Uri(path = path)))
      ).pure[F]
    }
  }
}
