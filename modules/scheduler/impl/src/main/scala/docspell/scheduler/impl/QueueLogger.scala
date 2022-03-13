/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect.std.Queue
import cats.effect.{Async, Sync}
import cats.syntax.all._
import fs2.Stream

import docspell.common.{Ident, LogLevel}
import docspell.logging
import docspell.logging.{Level, Logger}
import docspell.scheduler.LogEvent

object QueueLogger {

  def create[F[_]: Sync](
      jobId: Ident,
      jobInfo: String,
      q: Queue[F, LogEvent]
  ): Logger[F] =
    new Logger[F] {

      def log(logEvent: logging.LogEvent) =
        LogEvent
          .create[F](jobId, jobInfo, level2Level(logEvent.level), logEvent.msg())
          .flatMap { ev =>
            val event =
              logEvent.findErrors.headOption
                .map(ex => ev.copy(ex = Some(ex)))
                .getOrElse(ev)

            q.offer(event)
          }

      def asUnsafe = Logger.off
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

  private def level2Level(level: Level): LogLevel =
    LogLevel.fromLevel(level)
}
