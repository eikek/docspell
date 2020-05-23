package docspell.restserver

import cats.effect._
import cats.implicits._
import docspell.common.Pools
import docspell.backend.auth.AuthToken
import docspell.restserver.routes._
import docspell.restserver.webapp._
import fs2.Stream
import org.http4s._
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.server.middleware.Logger
import org.http4s.dsl.Http4sDsl

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
          securedRoutes(cfg, restApp, token)
        },
        "/api/doc"    -> templates.doc,
        "/app/assets" -> WebjarRoutes.appRoutes[F](pools.blocker),
        "/app"        -> templates.app,
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

  def securedRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth"                    -> LoginRoutes.session(restApp.backend.login, cfg),
      "tag"                     -> TagRoutes(restApp.backend, token),
      "equipment"               -> EquipmentRoutes(restApp.backend, token),
      "organization"            -> OrganizationRoutes(restApp.backend, token),
      "person"                  -> PersonRoutes(restApp.backend, token),
      "source"                  -> SourceRoutes(restApp.backend, token),
      "user"                    -> UserRoutes(restApp.backend, token),
      "collective"              -> CollectiveRoutes(restApp.backend, token),
      "queue"                   -> JobQueueRoutes(restApp.backend, token),
      "item"                    -> ItemRoutes(restApp.backend, token),
      "attachment"              -> AttachmentRoutes(restApp.backend, token),
      "upload"                  -> UploadRoutes.secured(restApp.backend, cfg, token),
      "checkfile"               -> CheckFileRoutes.secured(restApp.backend, token),
      "email/send"              -> MailSendRoutes(restApp.backend, token),
      "email/settings"          -> MailSettingsRoutes(restApp.backend, token),
      "email/sent"              -> SentMailRoutes(restApp.backend, token),
      "usertask/notifydueitems" -> NotifyDueItemsRoutes(cfg, restApp.backend, token),
      "usertask/scanmailbox"    -> ScanMailboxRoutes(restApp.backend, token),
      "calevent/check"          -> CalEventCheckRoutes()
    )

  def openRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "auth"      -> LoginRoutes.login(restApp.backend.login, cfg),
      "signup"    -> RegisterRoutes(restApp.backend, cfg),
      "upload"    -> UploadRoutes.open(restApp.backend, cfg),
      "checkfile" -> CheckFileRoutes.open(restApp.backend)
    )

  def redirectTo[F[_]: Effect](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        Response[F](
          Status.SeeOther,
          body = Stream.empty,
          headers = Headers.of(Location(Uri(path = path)))
        ).pure[F]
    }
  }
}
