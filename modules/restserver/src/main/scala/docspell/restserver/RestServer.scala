/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import scala.concurrent.duration._

import cats.effect._
import cats.implicits._
import fs2.Stream
import fs2.concurrent.Topic

import docspell.backend.msg.Topics
import docspell.common._
import docspell.pubsub.naive.NaivePubSub
import docspell.restserver.http4s.InternalHeader
import docspell.restserver.ws.OutputEvent
import docspell.restserver.ws.OutputEvent.KeepAlive
import docspell.store.Store
import docspell.store.records.RInternalSetting

import org.http4s._
import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.blaze.server.BlazeServerBuilder
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger
import org.http4s.server.websocket.WebSocketBuilder2

object RestServer {

  def serve[F[_]: Async](cfg: Config, pools: Pools): F[ExitCode] =
    for {
      wsTopic <- Topic[F, OutputEvent]
      keepAlive = Stream
        .awakeEvery[F](30.seconds)
        .map(_ => KeepAlive)
        .through(wsTopic.publish)

      server =
        Stream
          .resource(createApp(cfg, pools, wsTopic))
          .flatMap { case (restApp, pubSub, setting) =>
            Stream(
              restApp.subscriptions,
              restApp.eventConsume(2),
              BlazeServerBuilder[F]
                .bindHttp(cfg.bind.port, cfg.bind.address)
                .withoutBanner
                .withResponseHeaderTimeout(cfg.serverOptions.responseTimeout.toScala)
                .enableHttp2(cfg.serverOptions.enableHttp2)
                .withMaxConnections(cfg.serverOptions.maxConnections)
                .withHttpWebSocketApp(
                  createHttpApp(setting, pubSub, restApp)
                )
                .serve
                .drain
            )
          }

      exit <-
        (server ++ Stream(keepAlive)).parJoinUnbounded.compile.drain.as(ExitCode.Success)
    } yield exit

  def createApp[F[_]: Async](
      cfg: Config,
      pools: Pools,
      wsTopic: Topic[F, OutputEvent]
  ): Resource[
    F,
    (RestApp[F], NaivePubSub[F], RInternalSetting)
  ] =
    for {
      httpClient <- BlazeClientBuilder[F].resource
      store <- Store.create[F](
        cfg.backend.jdbc,
        cfg.backend.files.defaultFileRepositoryConfig,
        pools.connectEC
      )
      setting <- Resource.eval(store.transact(RInternalSetting.create))
      pubSub <- NaivePubSub(
        cfg.pubSubConfig(setting.internalRouteKey),
        store,
        httpClient
      )(Topics.all.map(_.topic))
      restApp <- RestAppImpl.create[F](cfg, store, httpClient, pubSub, wsTopic)
    } yield (restApp, pubSub, setting)

  def createHttpApp[F[_]: Async](
      internSettings: RInternalSetting,
      pubSub: NaivePubSub[F],
      restApp: RestApp[F]
  )(
      wsB: WebSocketBuilder2[F]
  ) = {
    val internal = Router(
      "/" -> redirectTo("/app"),
      "/internal" -> InternalHeader(internSettings.internalRouteKey) {
        internalRoutes(pubSub)
      }
    )
    val httpApp = (internal <+> restApp.routes(wsB)).orNotFound
    Logger.httpApp(logHeaders = false, logBody = false)(httpApp)
  }

  def internalRoutes[F[_]: Async](pubSub: NaivePubSub[F]): HttpRoutes[F] =
    Router(
      "pubsub" -> pubSub.receiveRoute
    )

  def redirectTo[F[_]: Async](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      Response[F](
        Status.SeeOther,
        body = Stream.empty,
        headers = Headers(Location(Uri(path = Uri.Path.unsafeFromString(path))))
      ).pure[F]
    }
  }
}
