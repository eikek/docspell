package docspell.joex.scheduler

import cats.implicits._
import docspell.common._
import cats.effect.Sync

case class LogEvent( jobId: Ident
                   , jobInfo: String
                   , time: Timestamp
                   , level: LogLevel
                   , msg: String
                   , ex: Option[Throwable] = None) {

  def logLine: String =
    s">>> ${time.asString} $level $jobInfo: $msg"

}

object LogEvent {

  def create[F[_]: Sync](jobId: Ident, jobInfo: String, level: LogLevel, msg: String): F[LogEvent] =
    Timestamp.current[F].map(now => LogEvent(jobId, jobInfo, now, level, msg))


}
