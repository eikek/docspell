package docspell.joex

import cats.effect._
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.implicits._
import fs2.Stream

import org.http4s.server.middleware.Logger
import org.http4s.server.Router

object JoexServer {

  def stream[F[_]: ConcurrentEffect](cfg: Config)
    (implicit T: Timer[F]): Stream[F, Nothing] = {

    val app = for {
      joexApp  <- JoexAppImpl.create[F](cfg)
      _        <- Resource.liftF(joexApp.init)

      httpApp = Router(
        "/api/info" -> InfoRoutes(cfg)
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
