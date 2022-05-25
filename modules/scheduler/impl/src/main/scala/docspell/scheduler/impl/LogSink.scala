/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import cats.implicits._
import fs2.Pipe

import docspell.common._
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
    val logger = docspell.logging
      .getLogger[F]
      .capture("jobId", e.jobId)
      .capture("task", e.taskName)
      .capture("group", e.group)
      .capture("jobInfo", e.jobInfo)
      .captureAll(e.data)

    e.level match {
      case LogLevel.Info =>
        logger.info(e.logLine)
      case LogLevel.Debug =>
        logger.debug(e.logLine)
      case LogLevel.Warn =>
        logger.warn(e.logLine)
      case LogLevel.Error =>
        e.ex match {
          case Some(exc) =>
            logger.error(exc)(e.logLine)
          case None =>
            logger.error(e.logLine)
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
