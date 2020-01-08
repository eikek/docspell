package docspell.restserver

import cats.effect._
import docspell.backend.auth.AuthToken
import docspell.restserver.routes._
import docspell.restserver.webapp._
import fs2.Stream
import org.http4s.HttpRoutes
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.server.middleware.Logger

import scala.concurrent.ExecutionContext

object RestServer {

  def stream[F[_]: ConcurrentEffect](
      cfg: Config,
      connectEC: ExecutionContext,
      httpClientEc: ExecutionContext,
      blocker: Blocker
  )(implicit T: Timer[F], CS: ContextShift[F]): Stream[F, Nothing] = {

    val templates = TemplateRoutes[F](blocker, cfg)
    val app = for {
      restApp <- RestAppImpl.create[F](cfg, connectEC, httpClientEc, blocker)
      httpApp = Router(
        "/api/info"     -> routes.InfoRoutes(),
        "/api/v1/open/" -> openRoutes(cfg, restApp),
        "/api/v1/sec/" -> Authenticate(restApp.backend.login, cfg.auth) { token =>
          securedRoutes(cfg, restApp, token)
        },
        "/api/doc"    -> templates.doc,
        "/app/assets" -> WebjarRoutes.appRoutes[F](blocker),
        "/app"        -> templates.app
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

  def securedRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth"           -> LoginRoutes.session(restApp.backend.login, cfg),
      "tag"            -> TagRoutes(restApp.backend, token),
      "equipment"      -> EquipmentRoutes(restApp.backend, token),
      "organization"   -> OrganizationRoutes(restApp.backend, token),
      "person"         -> PersonRoutes(restApp.backend, token),
      "source"         -> SourceRoutes(restApp.backend, token),
      "user"           -> UserRoutes(restApp.backend, token),
      "collective"     -> CollectiveRoutes(restApp.backend, token),
      "queue"          -> JobQueueRoutes(restApp.backend, token),
      "item"           -> ItemRoutes(restApp.backend, token),
      "attachment"     -> AttachmentRoutes(restApp.backend, token),
      "upload"         -> UploadRoutes.secured(restApp.backend, cfg, token),
      "checkfile"      -> CheckFileRoutes.secured(restApp.backend, token),
      "email/send"     -> MailSendRoutes(restApp.backend, token),
      "email/settings" -> MailSettingsRoutes(restApp.backend, token)
    )

  def openRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "auth"      -> LoginRoutes.login(restApp.backend.login, cfg),
      "signup"    -> RegisterRoutes(restApp.backend, cfg),
      "upload"    -> UploadRoutes.open(restApp.backend, cfg),
      "checkfile" -> CheckFileRoutes.open(restApp.backend)
    )
}
