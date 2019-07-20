package docspell.restserver

import cats.effect._
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.implicits._
import fs2.Stream

import org.http4s.server.middleware.Logger
import org.http4s.server.Router

import docspell.restserver.webapp._

object RestServer {

  def stream[F[_]: ConcurrentEffect](cfg: Config, blocker: Blocker)
    (implicit T: Timer[F], CS: ContextShift[F]): Stream[F, Nothing] = {

    val app = for {
      restApp  <- RestAppImpl.create[F](cfg)
      _        <- Resource.liftF(restApp.init)

      httpApp = Router(
        "/api/info" -> InfoRoutes(cfg),
        "/app/assets" -> WebjarRoutes.appRoutes[F](blocker, cfg),
        "/app" -> TemplateRoutes[F](blocker, cfg)
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(false, false)(httpApp)

    } yield finalHttpApp


    Stream.resource(app).flatMap(httpApp =>
      BlazeServerBuilder[F]
        .bindHttp(cfg.bind.port, cfg.bind.address)
        .withHttpApp(httpApp)
        .serve
    )

  }.drain
}
