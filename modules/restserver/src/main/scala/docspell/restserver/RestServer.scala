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
import fs2.io.file.Files
import fs2.io.net.Network

import docspell.backend.msg.Topics
import docspell.backend.ops.ONode
import docspell.common._
import docspell.pubsub.naive.NaivePubSub
import docspell.restserver.http4s.InternalHeader
import docspell.restserver.ws.OutputEvent
import docspell.restserver.ws.OutputEvent.KeepAlive
import docspell.store.Store
import docspell.store.records.RInternalSetting

import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.ember.client.EmberClientBuilder
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.middleware.Logger
import org.http4s.server.websocket.WebSocketBuilder2

object RestServer {

  def serve[F[_]: Async: Files: Network](
      cfg: Config,
      pools: Pools
  ): F[ExitCode] =
    for {
      wsTopic <- Topic[F, OutputEvent]
      keepAlive = Stream
        .awakeEvery[F](30.seconds)
        .map(_ => KeepAlive)
        .through(wsTopic.publish)

      logger = docspell.logging.getLogger[F]
      _ <- logger.info(s"Starting server with options ${cfg.serverOptions}")

      server =
        Stream
          .resource(createApp(cfg, pools, wsTopic))
          .flatMap { case (restApp, pubSub, setting) =>
            Stream(
              restApp.subscriptions,
              restApp.eventConsume(maxConcurrent = 2),
              Stream.eval {
                EmberServerBuilder
                  .default[F]
                  .withHost(cfg.bind.address)
                  .withPort(cfg.bind.port)
                  .withMaxConnections(cfg.serverOptions.maxConnections)
                  .withHttpWebSocketApp(createHttpApp(setting, pubSub, restApp))
                  .toggleHttp2(cfg.serverOptions.enableHttp2)
                  .build
                  .useForever
              }
            )
          }
      exit <-
        (server ++ Stream(keepAlive)).parJoinUnbounded.compile.drain.as(ExitCode.Success)
    } yield exit

  def createApp[F[_]: Async: Files: Network](
      cfg: Config,
      pools: Pools,
      wsTopic: Topic[F, OutputEvent]
  ): Resource[
    F,
    (RestApp[F], NaivePubSub[F], RInternalSetting)
  ] =
    for {
      httpClient <- EmberClientBuilder.default[F].build
      store <- Store.create[F](
        cfg.backend.jdbc,
        cfg.backend.databaseSchema,
        cfg.backend.files.defaultFileRepositoryConfig,
        pools.connectEC
      )
      setting <- Resource.eval(store.transact(RInternalSetting.create))
      pubSub <- NaivePubSub(
        cfg.pubSubConfig(setting.internalRouteKey),
        store,
        httpClient
      )(Topics.all.map(_.topic))

      nodes <- ONode(store)
      _ <- nodes.withRegistered(
        cfg.appId,
        NodeType.Restserver,
        cfg.baseUrl,
        cfg.auth.serverSecret.some
      )

      restApp <- RestAppImpl
        .create[F](cfg, pools, store, httpClient, pubSub, wsTopic)
    } yield (restApp, pubSub, setting)

  def createHttpApp[F[_]: Async](
      internSettings: RInternalSetting,
      pubSub: NaivePubSub[F],
      restApp: RestApp[F]
  )(
      wsB: WebSocketBuilder2[F]
  ) = {
    val logger = docspell.logging.getLogger[F]
    val internal = Router(
      "/" -> redirectTo("/app"),
      "/internal" -> InternalHeader(internSettings.internalRouteKey) {
        internalRoutes(pubSub)
      }
    )
    val httpApp = (internal <+> restApp.routes(wsB)).orNotFound
      .mapF(
        _.attempt
          .flatMap { eab =>
            eab.fold(
              ex =>
                logger.error(ex)("Processing the request resulted in an error.").as(eab),
              _ => eab.pure[F]
            )
          }
          .rethrow
      )
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

  implicit final class EmberServerBuilderExt[F[_]](self: EmberServerBuilder[F]) {
    def toggleHttp2(flag: Boolean) =
      if (flag) self.withHttp2 else self.withoutHttp2
  }
}
