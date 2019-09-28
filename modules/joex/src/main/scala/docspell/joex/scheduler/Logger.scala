package docspell.joex.scheduler

import cats.implicits._
import cats.effect.{Concurrent, Sync}
import docspell.common._
import fs2.concurrent.Queue

trait Logger[F[_]] {

  def trace(msg: => String): F[Unit]
  def debug(msg: => String): F[Unit]
  def info(msg: => String): F[Unit]
  def warn(msg: => String): F[Unit]
  def error(ex: Throwable)(msg: => String): F[Unit]
  def error(msg: => String): F[Unit]

}

object Logger {

  def create[F[_]: Sync](jobId: Ident, jobInfo: String, q: Queue[F, LogEvent]): Logger[F] =
    new Logger[F] {
      def trace(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Debug, msg).flatMap(q.enqueue1)

      def debug(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Debug, msg).flatMap(q.enqueue1)

      def info(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Info, msg).flatMap(q.enqueue1)

      def warn(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Warn, msg).flatMap(q.enqueue1)

      def error(ex: Throwable)(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Error, msg).map(le => le.copy(ex = Some(ex))).flatMap(q.enqueue1)

      def error(msg: => String): F[Unit] =
        LogEvent.create[F](jobId, jobInfo, LogLevel.Error, msg).flatMap(q.enqueue1)
    }

  def apply[F[_]: Concurrent](jobId: Ident, jobInfo: String, bufferSize: Int, sink: LogSink[F]): F[Logger[F]] =
    for {
      q    <- Queue.circularBuffer[F, LogEvent](bufferSize)
      log   = create(jobId, jobInfo, q)
      _    <- Concurrent[F].start(q.dequeue.through(sink.receive).compile.drain)
    } yield log

}