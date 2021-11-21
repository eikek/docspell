/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Applicative
import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._
import cats.kernel.Monoid
import fs2.Stream

import docspell.common._

/** Pushes notification messages/events to an external system */
trait NotificationBackend[F[_]] {

  def send(event: EventContext): F[Unit]

}

object NotificationBackend {

  def apply[F[_]](run: EventContext => F[Unit]): NotificationBackend[F] =
    (event: EventContext) => run(event)

  def silent[F[_]: Applicative]: NotificationBackend[F] =
    NotificationBackend(_ => ().pure[F])

  def combine[F[_]: Concurrent](
      ba: NotificationBackend[F],
      bb: NotificationBackend[F]
  ): NotificationBackend[F] =
    (ba, bb) match {
      case (a: Combined[F], b: Combined[F]) =>
        Combined(a.delegates.concatNel(b.delegates))
      case (a: Combined[F], _) =>
        Combined(bb :: a.delegates)
      case (_, b: Combined[F]) =>
        Combined(ba :: b.delegates)
      case (_, _) =>
        Combined(NonEmptyList.of(ba, bb))
    }

  def ignoreErrors[F[_]: Sync](
      logger: Logger[F]
  )(nb: NotificationBackend[F]): NotificationBackend[F] =
    NotificationBackend { event =>
      nb.send(event).attempt.flatMap {
        case Right(_) =>
          logger.debug(s"Successfully sent notification: $event")
        case Left(ex) =>
          logger.error(ex)(s"Error sending notification: $event")
      }
    }

  final private case class Combined[F[_]: Concurrent](
      delegates: NonEmptyList[NotificationBackend[F]]
  ) extends NotificationBackend[F] {
    val parNum = math.max(2, Runtime.getRuntime.availableProcessors() * 2)

    def send(event: EventContext): F[Unit] =
      Stream
        .emits(delegates.toList)
        .covary[F]
        .parEvalMapUnordered(math.min(delegates.size, parNum))(_.send(event))
        .drain
        .compile
        .drain
  }

  def combineAll[F[_]: Concurrent](
      bes: NonEmptyList[NotificationBackend[F]]
  ): NotificationBackend[F] =
    bes.tail match {
      case Nil => bes.head
      case next :: Nil =>
        Combined(NonEmptyList.of(bes.head, next))
      case next :: more =>
        val first: NotificationBackend[F] = Combined(NonEmptyList.of(bes.head, next))
        more.foldLeft(first)(combine)
    }

  implicit def monoid[F[_]: Concurrent]: Monoid[NotificationBackend[F]] =
    Monoid.instance(silent[F], combine[F])
}
