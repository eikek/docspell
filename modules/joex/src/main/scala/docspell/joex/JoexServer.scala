package docspell.joex

import cats.effect._
import cats.effect.concurrent.Ref
import docspell.joex.routes._
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.implicits._
import fs2.Stream
import fs2.concurrent.SignallingRef
import org.http4s.HttpApp
import org.http4s.server.middleware.Logger
import org.http4s.server.Router

import scala.concurrent.ExecutionContext

object JoexServer {


  private case class App[F[_]](httpApp: HttpApp[F], termSig: SignallingRef[F, Boolean], exitRef: Ref[F, ExitCode])

  def stream[F[_]: ConcurrentEffect : ContextShift](cfg: Config, connectEC: ExecutionContext, blocker: Blocker)
    (implicit T: Timer[F]): Stream[F, Nothing] = {

    val app = for {
      signal <- Resource.liftF(SignallingRef[F, Boolean](false))
      exitCode <- Resource.liftF(Ref[F].of(ExitCode.Success))
      joexApp  <- JoexAppImpl.create[F](cfg, signal, connectEC, blocker)

      httpApp = Router(
        "/api/info" -> InfoRoutes(),
        "/api/v1" -> JoexRoutes(joexApp)
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(false, false)(httpApp)

    } yield App(finalHttpApp, signal, exitCode)


    Stream.resource(app).flatMap(app =>
      BlazeServerBuilder[F].
        bindHttp(cfg.bind.port, cfg.bind.address).
        withHttpApp(app.httpApp).
        withoutBanner.
        serveWhile(app.termSig, app.exitRef)
    )

  }.drain
}
