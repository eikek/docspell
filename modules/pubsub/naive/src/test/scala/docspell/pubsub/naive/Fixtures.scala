/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import cats.effect._

import docspell.common._
import docspell.logging.Logger
import docspell.pubsub.api._
import docspell.store.{Store, StoreFixture}

import munit.CatsEffectSuite
import org.http4s.client.Client
import org.http4s.{Header, Response}
import org.typelevel.ci._

trait Fixtures extends HttpClientOps { self: CatsEffectSuite =>

  val pubsubEnv = ResourceFunFixture(Fixtures.envResource("node-1"))

  val pubsubT = ResourceFunFixture {
    Fixtures
      .envResource("node-1")
      .flatMap(_.pubSub)
      .map(ps => PubSubT(ps, Fixtures.loggerIO))
  }

  def conntectedPubsubs(env: Fixtures.Env) =
    for {
      // Create two pubsub instances connected to the same database
      ps_1 <- env.withNodeId("node-1").pubSubT
      ps_2 <- env.withNodeId("node-2").pubSubT

      // both instances have a dummy client. now connect their clients to each other
      ps1 = ps_1.withDelegate(ps_1.delegateT.withClient(httpClient(ps_2)))
      ps2 = ps_2.withDelegate(ps_2.delegateT.withClient(httpClient(ps_1)))
    } yield (ps1, ps2)

  implicit final class StringId(s: String) {
    def id: Ident = Ident.unsafe(s)
  }
}

object Fixtures {
  private val loggerIO: Logger[IO] = Logger.simpleDefault[IO]()

  final case class Env(store: Store[IO], cfg: PubSubConfig) {
    def pubSub: Resource[IO, NaivePubSub[IO]] = {
      val dummyClient = Client[IO](_ => Resource.pure(Response.notFound[IO]))
      NaivePubSub(cfg, store, dummyClient)(Topics.all.map(_.topic))
    }
    def pubSubT: Resource[IO, PubSubT[IO]] =
      pubSub.map(PubSubT(_, loggerIO))

    def withNodeId(nodeId: String): Env =
      copy(cfg =
        cfg.copy(
          nodeId = Ident.unsafe(nodeId),
          url = LenientUri.unsafe(s"http://$nodeId/")
        )
      )
  }

  def testConfig(nodeId: String) =
    PubSubConfig(
      Ident.unsafe(nodeId),
      LenientUri.unsafe(s"http://$nodeId/"),
      0,
      Header.Raw(ci"Docspell-Internal", "abc")
    )

  def storeResource: Resource[IO, Store[IO]] =
    for {
      random <- Resource.eval(Ident.randomId[IO])
      cfg = StoreFixture.memoryDB(random.id.take(12))
      store <- StoreFixture.store(cfg)
      _ <- Resource.eval(store.migrate)
    } yield store

  def envResource(nodeId: String): Resource[IO, Env] =
    for {
      store <- storeResource
    } yield Env(store, testConfig(nodeId))
}
