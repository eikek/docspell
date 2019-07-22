package docspell.restserver

import cats.effect._
import docspell.backend.auth.AuthToken
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.implicits._
import fs2.Stream
import org.http4s.server.middleware.Logger
import org.http4s.server.Router
import docspell.restserver.webapp._
import docspell.restserver.routes._
import org.http4s.HttpRoutes

import scala.concurrent.ExecutionContext

object RestServer {

  def stream[F[_]: ConcurrentEffect](cfg: Config, connectEC: ExecutionContext, httpClientEc: ExecutionContext, blocker: Blocker)
    (implicit T: Timer[F], CS: ContextShift[F]): Stream[F, Nothing] = {

    val app = for {
      restApp  <- RestAppImpl.create[F](cfg, connectEC, httpClientEc, blocker)

      httpApp = Router(
        "/api/info" -> routes.InfoRoutes(cfg),
        "/api/v1/open/" -> openRoutes(cfg, restApp),
        "/api/v1/sec/" -> Authenticate(restApp.backend.login, cfg.auth) {
          token => securedRoutes(cfg, restApp, token)
        },
        "/app/assets" -> WebjarRoutes.appRoutes[F](blocker, cfg),
        "/app" -> TemplateRoutes[F](blocker, cfg)
      ).orNotFound

      finalHttpApp = Logger.httpApp(logHeaders = false, logBody = false)(httpApp)

    } yield finalHttpApp

    Stream.resource(app).flatMap(httpApp =>
      BlazeServerBuilder[F].
        bindHttp(cfg.bind.port, cfg.bind.address).
        withHttpApp(httpApp).
        withoutBanner.
        serve)
  }.drain


  def securedRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F], token: AuthToken): HttpRoutes[F] =
    Router(
      "auth" -> LoginRoutes.session(restApp.backend.login, cfg),
      "tag" -> TagRoutes(restApp.backend, cfg, token),
      "equipment" -> EquipmentRoutes(restApp.backend, cfg, token),
      "organization" -> OrganizationRoutes(restApp.backend, cfg, token),
      "person" -> PersonRoutes(restApp.backend, cfg, token),
      "source" -> SourceRoutes(restApp.backend, cfg, token),
      "user" -> UserRoutes(restApp.backend, cfg, token),
      "collective" -> CollectiveRoutes(restApp.backend, cfg, token),
      "queue" -> JobQueueRoutes(restApp.backend, cfg, token),
      "item" -> ItemRoutes(restApp.backend, cfg, token),
      "attachment" -> AttachmentRoutes(restApp.backend, cfg, token),
      "upload" -> UploadRoutes.secured(restApp.backend, cfg, token)
    )

  def openRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F]): HttpRoutes[F] =
    Router(
      "auth" -> LoginRoutes.login(restApp.backend.login, cfg),
      "signup" -> RegisterRoutes(restApp.backend, cfg),
      "upload" -> UploadRoutes.open(restApp.backend, cfg)
    )
}
