/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect._
import fs2.Stream
import fs2.concurrent.SignallingRef
import fs2.io.file.Files
import fs2.io.net.Network

import docspell.backend.msg.Topics
import docspell.common.Pools
import docspell.common.util.ResourceUse.Implicits._
import docspell.joex.routes._
import docspell.pubsub.naive.NaivePubSub
import docspell.store.Store
import docspell.store.records.RInternalSetting

import org.http4s.HttpApp
import org.http4s.ember.client.EmberClientBuilder
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger

object JoexServer {

  private case class App[F[_]](
      httpApp: HttpApp[F],
      termSig: SignallingRef[F, Boolean],
      exitRef: Ref[F, ExitCode]
  )

  def stream[F[_]: Async: Files: Network](
      cfg: Config,
      pools: Pools
  ): Stream[F, Nothing] = {

    val app = for {
      signal <- Resource.eval(SignallingRef[F, Boolean](false))
      exitCode <- Resource.eval(Ref[F].of(ExitCode.Success))

      store <- Store.create[F](
        cfg.jdbc,
        cfg.databaseSchema,
        cfg.files.defaultFileRepositoryConfig,
        pools.connectEC
      )
      settings <- Resource.eval(store.transact(RInternalSetting.create))
      httpClient <- EmberClientBuilder.default[F].build
      pubSub <- NaivePubSub(
        cfg.pubSubConfig(settings.internalRouteKey),
        store,
        httpClient
      )(Topics.all.map(_.topic))

      joexApp <- JoexAppImpl.create[F](cfg, signal, store, httpClient, pubSub, pools)

      httpApp = Router(
        "/internal" -> InternalHeader(settings.internalRouteKey) {
          Router("pubsub" -> pubSub.receiveRoute)
        },
        "/api/info" -> InfoRoutes(cfg),
        "/api/v1" -> JoexRoutes(cfg, joexApp)
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(logHeaders = false, logBody = false)(httpApp)

    } yield App(finalHttpApp, signal, exitCode)

    Stream
      .resource(app)
      .evalMap { app =>
        EmberServerBuilder
          .default[F]
          .withHost(cfg.bind.address)
          .withPort(cfg.bind.port)
          .withHttpApp(app.httpApp)
          .build
          .useUntil(app.termSig, app.exitRef)
      }
  }.drain
}
