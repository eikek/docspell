/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect._
import cats.implicits._
import fs2.Pipe

import docspell.common._
import docspell.logging
import docspell.store.Store
import docspell.store.records.RJobLog

trait LogSink[F[_]] {

  def receive: Pipe[F, LogEvent, Unit]

}

object LogSink {

  def apply[F[_]](sink: Pipe[F, LogEvent, Unit]): LogSink[F] =
    new LogSink[F] {
      val receive = sink
    }

  def logInternal[F[_]: Sync](e: LogEvent): F[Unit] = {
    val logger = docspell.logging.getLogger[F]
    val addData: logging.LogEvent => logging.LogEvent =
      _.data("jobId", e.jobId).data("jobInfo", e.jobInfo)

    e.level match {
      case LogLevel.Info =>
        logger.infoWith(e.logLine)(addData)
      case LogLevel.Debug =>
        logger.debugWith(e.logLine)(addData)
      case LogLevel.Warn =>
        logger.warnWith(e.logLine)(addData)
      case LogLevel.Error =>
        e.ex match {
          case Some(exc) =>
            logger.errorWith(e.logLine)(addData.andThen(_.addError(exc)))
          case None =>
            logger.errorWith(e.logLine)(addData)
        }
    }
  }

  def printer[F[_]: Sync]: LogSink[F] =
    LogSink(_.evalMap(e => logInternal(e)))

  def db[F[_]: Async](store: Store[F]): LogSink[F] =
    LogSink(
      _.evalMap(ev =>
        for {
          id <- Ident.randomId[F]
          joblog = RJobLog(
            id,
            ev.jobId,
            ev.level,
            ev.time,
            ev.msg + ev.ex.map(th => ": " + th.getMessage).getOrElse("")
          )
          _ <- logInternal(ev)
          _ <- store.transact(RJobLog.insert(joblog))
        } yield ()
      )
    )

  def dbAndLog[F[_]: Async](store: Store[F]): LogSink[F] =
    LogSink(_.broadcastThrough(printer[F].receive, db[F](store).receive))
}
