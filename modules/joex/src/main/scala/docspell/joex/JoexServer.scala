/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect.Ref
import cats.effect._
import fs2.Stream
import fs2.concurrent.SignallingRef

import docspell.common.Pools
import docspell.joex.routes._

import org.http4s.HttpApp
import org.http4s.blaze.server.BlazeServerBuilder
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger

object JoexServer {

  private case class App[F[_]](
      httpApp: HttpApp[F],
      termSig: SignallingRef[F, Boolean],
      exitRef: Ref[F, ExitCode]
  )

  def stream[F[_]: Async](cfg: Config, pools: Pools): Stream[F, Nothing] = {

    val app = for {
      signal <- Resource.eval(SignallingRef[F, Boolean](false))
      exitCode <- Resource.eval(Ref[F].of(ExitCode.Success))
      joexApp <-
        JoexAppImpl
          .create[F](cfg, signal, pools.connectEC, pools.httpClientEC)

      httpApp = Router(
        "/api/info" -> InfoRoutes(cfg),
        "/api/v1" -> JoexRoutes(joexApp)
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(false, false)(httpApp)

    } yield App(finalHttpApp, signal, exitCode)

    Stream
      .resource(app)
      .flatMap(app =>
        BlazeServerBuilder[F](pools.restEC)
          .bindHttp(cfg.bind.port, cfg.bind.address)
          .withHttpApp(app.httpApp)
          .withoutBanner
          .serveWhile(app.termSig, app.exitRef)
      )

  }.drain
}
