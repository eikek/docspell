/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._
import fs2.Pipe
import fs2.Stream
import fs2.concurrent.{Topic => Fs2Topic}

import docspell.common._
import docspell.pubsub.api._
import docspell.pubsub.naive.NaivePubSub.State
import docspell.store.Store
import docspell.store.records.RPubSub

import io.circe.Json
import org.http4s.circe.CirceEntityCodec._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.dsl.Http4sDsl
import org.http4s.{HttpRoutes, Uri}

/** A pubsub implementation that can be used across machines, using a rather inefficient
  * but simple protocol. It can therefore work with the current setup, i.e. not requiring
  * to add another complex piece of software to the mix, like Kafka or RabbitMQ.
  *
  * However, the api should allow to be used on top of such a tool. This implementation
  * can be used in a personal setting, where there are only a few nodes.
  *
  * How it works: Each node has a set of local subscribers and a http endpoint. If it
  * publishes a message, it notifies all local subscribers and sends out a json message to
  * all endpoints that are registered for this topic. If it receives a messagen through
  * its endpoint, it notifies all local subscribers.
  *
  * It is build on the `Topic` class from fs2.concurrent. A map of the name to such a
  * `Topic` instance is maintained. To work across machines, the database is used as a
  * synchronization point. Each node must provide a http api and so its "callback" URL is
  * added into the database associated to a topic name.
  *
  * When publishing a message, the message can be published to the internal fs2 topic.
  * Then all URLs to this topic name are looked up in the database and the message is
  * POSTed to each URL as JSON. The endpoint of each machine takes this message and
  * publishes it to its own internal fs2.concurrent.Topic instance.
  *
  * Obviously, this doesn't scale well to lots of machines and messages. It should be good
  * enough for personal use, where there are only a small amount of machines and messages.
  *
  * The main use case for docspell is to communicate between the rest-server and job
  * executor. It is for internal communication and all topics are known at compile time.
  */
final class NaivePubSub[F[_]: Async](
    cfg: PubSubConfig,
    state: Ref[F, State[F]],
    store: Store[F],
    client: Client[F]
) extends PubSub[F] {
  private val logger: Logger[F] = Logger.log4s(org.log4s.getLogger)

  def withClient(client: Client[F]): NaivePubSub[F] =
    new NaivePubSub[F](cfg, state, store, client)

  def publish1(topic: Topic, msgBody: Json): F[MessageHead] =
    for {
      head <- mkMessageHead(topic)
      msg = Message(head, msgBody)
      _ <- logger.trace(s"Publishing: $msg")
      // go through all local subscribers and publish to the fs2 topic
      _ <- publishLocal(msg)
      // get all remote subscribers from the database and send the message via http
      _ <- publishRemote(msg)
    } yield head

  def publish(topic: Topic): Pipe[F, Json, MessageHead] =
    ms => //TODO Do some optimization by grouping messages to the same topic
      ms.evalMap(publish1(topic, _))

  def subscribe(topics: NonEmptyList[Topic]): Stream[F, Message[Json]] =
    (for {
      _ <- logger.s.info(s"Adding subscriber for topics: $topics")
      _ <- Stream.resource[F, Unit](addRemote(topics))
      m <- Stream.eval(addLocal(topics))
    } yield m).flatten

  /** Receive messages from remote publishers and passes them to the local subscribers. */
  def receiveRoute: HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root =>
      for {
        data <- req.as[List[Message[Json]]]
        _ <- logger.trace(s"Received external message(s): $data")
        _ <- data.traverse(publishLocal)
        resp <- Ok(())
      } yield resp
    }
  }

  // ---- private helpers

  private def mkMessageHead(topic: Topic): F[MessageHead] =
    for {
      id <- Ident.randomId[F]
      ts <- Timestamp.current[F]
      head = MessageHead(id, ts, topic)
    } yield head

  private def addLocal(topics: NonEmptyList[Topic]): F[Stream[F, Message[Json]]] = {
    val topicSet = topics.map(_.name).toList.toSet
    for {
      st <- state.get
      tpc = st.topics.view.filterKeys(topicSet.contains)
      _ <-
        if (tpc.isEmpty)
          logger.warn(s"Subscribing to 0 topics! Topics $topics were not initialized")
        else ().pure[F]
      data = tpc.values.toList.traverse(t => t.subscribe(cfg.subscriberQueueSize))
      out = data.flatMap(msgs => Stream.emits(msgs))
    } yield out
  }

  private def addRemote(topics: NonEmptyList[Topic]): Resource[F, Unit] = {
    def subscribe: F[Unit] =
      logger.trace(s"Incrementing counter for topics: $topics") *>
        store.transact(RPubSub.increment(cfg.url, topics.map(_.name))).as(())

    def unsubscribe: F[Unit] =
      logger.trace(s"Decrementing counter for topics: $topics") *>
        store.transact(RPubSub.decrement(cfg.url, topics.map(_.name))).as(())

    Resource.make(subscribe)(_ => unsubscribe)
  }

  private def publishLocal(msg: Message[Json]): F[Unit] =
    for {
      st <- state.get
      _ <- st.topics.get(msg.head.topic.name) match {
        case Some(sub) =>
          logger.trace(s"Publishing message to local topic: $msg") *>
            sub.publish1(msg).as(())
        case None =>
          ().pure[F]
      }
    } yield ()

  private def publishRemote(msg: Message[Json]): F[Unit] = {
    val dsl = new Http4sDsl[F] with Http4sClientDsl[F] {}
    import dsl._

    for {
      _ <- logger.trace(s"Find all nodes subscribed to topic ${msg.head.topic.name}")
      urls <- store.transact(RPubSub.findSubs(msg.head.topic.name, cfg.nodeId))
      _ <- logger.trace(s"Publishing to remote urls ${urls.map(_.asString)}: $msg")
      reqs = urls
        .map(u => Uri.unsafeFromString(u.asString))
        .map(uri => POST(List(msg), uri).putHeaders(cfg.reqHeader))
      resList <- reqs.traverse(req => client.status(req).attempt)
      _ <- resList.traverse {
        case Right(s) =>
          if (s.isSuccess) ().pure[F]
          else logger.warn(s"A node was not reached! Reason: $s, message: $msg")
        case Left(ex) =>
          logger.error(ex)(s"Error publishing ${msg.head.topic.name} message remotely")
      }
    } yield ()
  }
}

object NaivePubSub {

  def apply[F[_]: Async](
      cfg: PubSubConfig,
      store: Store[F],
      client: Client[F]
  )(topics: NonEmptyList[Topic]): Resource[F, NaivePubSub[F]] =
    Resource.eval(for {
      state <- Ref.ofEffect[F, State[F]](State.create[F](topics))
      _ <- store.transact(RPubSub.initTopics(cfg.nodeId, cfg.url, topics.map(_.name)))
    } yield new NaivePubSub[F](cfg, state, store, client))

  def create[F[_]: Async](
      cfg: PubSubConfig,
      store: Store[F],
      client: Client[F],
      logger: Logger[F]
  )(topics: NonEmptyList[Topic]): Resource[F, PubSubT[F]] =
    apply[F](cfg, store, client)(topics).map(ps => PubSubT(ps, logger))

  final case class State[F[_]](topics: Map[String, Fs2Topic[F, Message[Json]]]) {}

  object State {
    def empty[F[_]]: State[F] = State[F](Map.empty)
    def create[F[_]: Async](topics: NonEmptyList[Topic]): F[State[F]] =
      topics
        .traverse(t => Fs2Topic[F, Message[Json]].map(fs2t => t.name -> fs2t))
        .map(_.toList.toMap)
        .map(State.apply)
  }
}
