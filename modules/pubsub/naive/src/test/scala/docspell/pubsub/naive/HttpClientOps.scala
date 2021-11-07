/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import cats.effect._

import docspell.common._
import docspell.pubsub.api._

import io.circe.Encoder
import org.http4s.circe.CirceEntityCodec._
import org.http4s.client.Client
import org.http4s.client.dsl.io._
import org.http4s.dsl.io._
import org.http4s.{HttpApp, HttpRoutes, Uri}

trait HttpClientOps {
  def httpClient(routes: HttpRoutes[IO]): Client[IO] =
    Client.fromHttpApp(HttpApp(routes.orNotFound.run))

  def httpClient(ps: NaivePubSub[IO]): Client[IO] =
    httpClient(ps.receiveRoute)

  def httpClient(ps: PubSubT[IO]): Client[IO] =
    httpClient(ps.delegateT)

  implicit final class ClientOps(client: Client[IO]) {
    val uri = Uri.unsafeFromString("http://localhost/")

    def sendMessage[A: Encoder](topic: Topic, body: A): IO[Unit] = {
      val encode: Encoder[List[Message[A]]] = implicitly[Encoder[List[Message[A]]]]

      for {
        id <- Ident.randomId[IO]
        time <- Timestamp.current[IO]
        mesg = List(Message(MessageHead(id, time, topic), body))
        _ <- HttpClientOps.logger.debug(s"Sending message(s): $mesg")
        _ <- client.expectOr[Unit](POST(encode(mesg), uri)) { resp =>
          IO(new Exception(s"Unexpected response: $resp"))
        }
      } yield ()
    }

    def send[A](typedTopic: TypedTopic[A], body: A): IO[Unit] =
      sendMessage(typedTopic.topic, body)(typedTopic.codec)
  }

  implicit final class PubSubTestOps(ps: PubSubT[IO]) {
    def delegateT: NaivePubSub[IO] = ps.delegate.asInstanceOf[NaivePubSub[IO]]
  }
}

object HttpClientOps {
  private val logger: Logger[IO] = Logger.log4s(org.log4s.getLogger)
}
