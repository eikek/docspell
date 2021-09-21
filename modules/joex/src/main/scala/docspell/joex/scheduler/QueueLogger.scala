/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.scheduler

import cats.effect._
import cats.effect.std.Queue
import cats.implicits._
import fs2.Stream

import docspell.common._

object QueueLogger {

  def create[F[_]: Sync](
      jobId: Ident,
      jobInfo: String,
      q: Queue[F, LogEvent]
  ): Logger[F] =
    new Logger[F] {
      def trace(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Debug, msg).flatMap(q.offer)

      def debug(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Debug, msg).flatMap(q.offer)

      def info(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Info, msg).flatMap(q.offer)

      def warn(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Warn, msg).flatMap(q.offer)

      def error(ex: Throwable)(msg: => String): F[Unit] =
        LogEvent
          .create[F](jobId, jobInfo, LogLevel.Error, msg)
          .map(le => le.copy(ex = Some(ex)))
          .flatMap(q.offer)

      def error(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Error, msg).flatMap(q.offer)
    }

  def apply[F[_]: Async](
      jobId: Ident,
      jobInfo: String,
      bufferSize: Int,
      sink: LogSink[F]
  ): F[Logger[F]] =
    for {
      q <- Queue.circularBuffer[F, LogEvent](bufferSize)
      log = create(jobId, jobInfo, q)
      _ <- Async[F].start(
        Stream.fromQueueUnterminated(q).through(sink.receive).compile.drain
      )
    } yield log

}
