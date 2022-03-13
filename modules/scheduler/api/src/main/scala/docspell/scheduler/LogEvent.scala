/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect.Sync
import cats.implicits._

import docspell.common._

case class LogEvent(
    jobId: Ident,
    jobInfo: String,
    time: Timestamp,
    level: LogLevel,
    msg: String,
    ex: Option[Throwable] = None
) {

  def logLine: String =
    s">>> ${time.asString} $level $jobInfo: $msg"

}

object LogEvent {

  def create[F[_]: Sync](
      jobId: Ident,
      jobInfo: String,
      level: LogLevel,
      msg: String
  ): F[LogEvent] =
    Timestamp.current[F].map(now => LogEvent(jobId, jobInfo, now, level, msg))

}
