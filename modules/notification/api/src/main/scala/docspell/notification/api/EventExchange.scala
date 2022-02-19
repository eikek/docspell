/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Applicative
import cats.data.Kleisli
import cats.effect._
import cats.effect.std.Queue
import cats.implicits._
import fs2.Stream

import docspell.logging.Logger

/** Combines a sink and reader to a place where events can be submitted and processed in a
  * producer-consumer manner.
  */
trait EventExchange[F[_]] extends EventSink[F] with EventReader[F] {}

object EventExchange {
  def silent[F[_]: Applicative]: EventExchange[F] =
    new EventExchange[F] {
      def offer(event: Event): F[Unit] =
        EventSink.silent[F].offer(event)

      def consume(maxConcurrent: Int)(run: Kleisli[F, Event, Unit]): Stream[F, Nothing] =
        Stream.empty.covary[F]
    }

  def circularQueue[F[_]: Async](queueSize: Int): F[EventExchange[F]] =
    Queue.circularBuffer[F, Event](queueSize).map(q => new Impl(q))

  final class Impl[F[_]: Async](queue: Queue[F, Event]) extends EventExchange[F] {
    private[this] val log: Logger[F] = docspell.logging.getLogger[F]

    def offer(event: Event): F[Unit] =
      log.debug(s"Pushing event to queue: $event") *>
        queue.offer(event)

    private val logEvent: Kleisli[F, Event, Unit] =
      Kleisli(ev => log.debug(s"Consuming event: $ev"))

    def consume(maxConcurrent: Int)(run: Kleisli[F, Event, Unit]): Stream[F, Nothing] = {
      val stream = Stream.repeatEval(queue.take).evalMap((logEvent >> run).run)
      log.stream.info(s"Starting up $maxConcurrent notification event consumers").drain ++
        Stream(stream).repeat.take(maxConcurrent.toLong).parJoin(maxConcurrent).drain
    }
  }
}
