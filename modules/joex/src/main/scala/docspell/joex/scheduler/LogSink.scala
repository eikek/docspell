package docspell.joex.scheduler

import cats.implicits._
import cats.effect.{Concurrent, Sync}
import fs2.{Pipe, Stream}
import org.log4s.{LogLevel => _, _}
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.records.RJobLog

trait LogSink[F[_]] {

  def receive: Pipe[F, LogEvent, Unit]

}

object LogSink {
  private[this] val logger = getLogger

  def apply[F[_]](sink: Pipe[F, LogEvent, Unit]): LogSink[F] =
    new LogSink[F] {
      val receive = sink
    }

  def logInternal[F[_]: Sync](e: LogEvent): F[Unit] =
    e.level match {
      case LogLevel.Info =>
        logger.finfo(e.logLine)
      case LogLevel.Debug =>
        logger.fdebug(e.logLine)
      case LogLevel.Warn =>
        logger.fwarn(e.logLine)
      case LogLevel.Error =>
        e.ex match {
          case Some(exc) =>
            logger.ferror(exc)(e.logLine)
          case None =>
            logger.ferror(e.logLine)
        }
    }

  def printer[F[_]: Sync]: LogSink[F] =
    LogSink(_.evalMap(e => logInternal(e)))

  def db[F[_]: Sync](store: Store[F]): LogSink[F] =
    LogSink(_.evalMap(ev => for {
      id     <- Ident.randomId[F]
      joblog  = RJobLog(id, ev.jobId, ev.level, ev.time, ev.msg + ev.ex.map(th => ": "+ th.getMessage).getOrElse(""))
      _      <- logInternal(ev)
      _      <- store.transact(RJobLog.insert(joblog))
    } yield ()))

  def dbAndLog[F[_]: Concurrent](store: Store[F]): LogSink[F] = {
    val s: Stream[F, Pipe[F, LogEvent, Unit]] =
      Stream.emits(Seq(printer[F].receive, db[F](store).receive))
    LogSink(Pipe.join(s))
  }
}
