/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import scala.concurrent.duration._

import cats.effect._
import cats.implicits._
import fs2.concurrent.SignallingRef

import docspell.common._
import docspell.pubsub.api._
import docspell.pubsub.naive.Topics._

import munit.CatsEffectSuite

class NaivePubSubTest extends CatsEffectSuite with Fixtures {
  private[this] val logger = Logger.log4s[IO](org.log4s.getLogger)

  def subscribe[A](ps: PubSubT[IO], topic: TypedTopic[A]) =
    for {
      received <- Ref.of[IO, Option[Message[A]]](None)
      halt <- SignallingRef.of[IO, Boolean](false)
      fiber <- Async[IO].start(
        logger.debug(s"${Thread.currentThread()} Listening for messages...") *>
          ps.subscribe(topic)
            .evalMap(m =>
              logger.debug(s"Handling message: $m") *>
                received.set(Some(m)) *>
                halt.set(true)
            )
            .interruptWhen(halt)
            .compile
            .drain
      )
      _ <- IO.sleep(500.millis)
    } yield (received, halt, fiber)

  pubsubT.test("local publish receives message") { ps =>
    for {
      res <- subscribe(ps, Topics.jobSubmitted)
      (received, _, subFiber) = res
      headSend <- ps.publish1(Topics.jobSubmitted, JobSubmittedMsg("hello".id)).flatten
      outcome <- subFiber.join
      msgRec <- received.get
      _ = assert(outcome.isSuccess)
      _ = assertEquals(msgRec.map(_.head), Option(headSend))
    } yield ()
  }

  pubsubT.test("local publish to different topic doesn't receive") { ps =>
    val otherTopic = Topics.jobSubmitted.withTopic(Topic("other-name"))
    for {
      res <- subscribe(ps, Topics.jobSubmitted)
      (received, halt, subFiber) = res
      _ <- ps.publish1(otherTopic, JobSubmittedMsg("hello".id))
      _ <- IO.sleep(100.millis) //allow some time for receiving
      _ <- halt.set(true)
      outcome <- subFiber.join
      _ = assert(outcome.isSuccess)
      recMsg <- received.get
      _ = assert(recMsg.isEmpty)
    } yield ()
  }

  pubsubT.test("receive messages remotely") { ps =>
    val msg = JobSubmittedMsg("hello-remote".id)
    for {
      res <- subscribe(ps, Topics.jobSubmitted)
      (received, _, subFiber) = res
      client = httpClient(ps.delegateT.receiveRoute)
      _ <- client.send(Topics.jobSubmitted, msg)
      outcome <- subFiber.join
      msgRec <- received.get
      _ = assert(outcome.isSuccess)
      _ = assertEquals(msgRec.map(_.head.topic), Topics.jobSubmitted.topic.some)
      _ = assertEquals(msgRec.map(_.body), msg.some)
    } yield ()
  }

  pubsubEnv.test("send messages remotely") { env =>
    val msg = JobSubmittedMsg("hello-remote".id)

    // Create two pubsub instances connected to the same database
    conntectedPubsubs(env).use { case (ps1, ps2) =>
      for {
        // subscribe to ps1 and send via ps2
        res <- subscribe(ps1, Topics.jobSubmitted)
        (received, _, subFiber) = res
        _ <- ps2.publish1(Topics.jobSubmitted, msg)
        outcome <- subFiber.join
        msgRec <- received.get

        // check results
        _ = assert(outcome.isSuccess)
        _ = assertEquals(msgRec.map(_.head.topic), Topics.jobSubmitted.topic.some)
        _ = assertEquals(msgRec.map(_.body), msg.some)
      } yield ()
    }
  }

  pubsubEnv.test("do not receive remote message from other topic") { env =>
    val msg = JobCancelMsg("job-1".id)

    // Create two pubsub instances connected to the same database
    conntectedPubsubs(env).use { case (ps1, ps2) =>
      for {
        // subscribe to ps1 and send via ps2
        res <- subscribe(ps1, Topics.jobSubmitted)
        (received, halt, subFiber) = res
        _ <- ps2.publish1(Topics.jobCancel, msg)
        _ <- IO.sleep(100.millis)
        _ <- halt.set(true)
        outcome <- subFiber.join
        msgRec <- received.get

        // check results
        _ = assert(outcome.isSuccess)
        _ = assertEquals(msgRec, None)
      } yield ()
    }

  }
}
