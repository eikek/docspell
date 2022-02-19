/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect._
import fs2.Stream
import fs2.concurrent.Topic

import docspell.backend.BackendApp
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.notification.api.NotificationModule
import docspell.notification.impl.NotificationModuleImpl
import docspell.pubsub.api.{PubSub, PubSubT}
import docspell.restserver.ws.OutputEvent
import docspell.store.Store

import emil.javamail.JavaMailEmil
import org.http4s.client.Client

final class RestAppImpl[F[_]: Async](
    val config: Config,
    val backend: BackendApp[F],
    notificationMod: NotificationModule[F],
    wsTopic: Topic[F, OutputEvent],
    pubSub: PubSubT[F]
) extends RestApp[F] {

  def eventConsume(maxConcurrent: Int): Stream[F, Nothing] =
    notificationMod.consumeAllEvents(maxConcurrent)

  def subscriptions: Stream[F, Nothing] =
    Subscriptions[F](wsTopic, pubSub)
}

object RestAppImpl {

  def create[F[_]: Async](
      cfg: Config,
      store: Store[F],
      httpClient: Client[F],
      pubSub: PubSub[F],
      wsTopic: Topic[F, OutputEvent]
  ): Resource[F, RestApp[F]] = {
    val logger = docspell.logging.getLogger[F](s"restserver-${cfg.appId.id}")

    for {
      ftsClient <- createFtsClient(cfg)(httpClient)
      pubSubT = PubSubT(pubSub, logger)
      javaEmil = JavaMailEmil(cfg.backend.mailSettings)
      notificationMod <- Resource.eval(
        NotificationModuleImpl[F](store, javaEmil, httpClient, 200)
      )
      backend <- BackendApp
        .create[F](store, javaEmil, ftsClient, pubSubT, notificationMod)

      app = new RestAppImpl[F](cfg, backend, notificationMod, wsTopic, pubSubT)
    } yield app
  }

  private def createFtsClient[F[_]: Async](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])
}
