package docspell.common

import cats.effect.Sync
import docspell.common.syntax.all._
import org.log4s.{Logger => Log4sLogger}

trait Logger[F[_]] {

  def trace(msg: => String): F[Unit]
  def debug(msg: => String): F[Unit]
  def info(msg: => String): F[Unit]
  def warn(msg: => String): F[Unit]
  def error(ex: Throwable)(msg: => String): F[Unit]
  def error(msg: => String): F[Unit]

}

object Logger {

  def log4s[F[_]: Sync](log: Log4sLogger): Logger[F] =
    new Logger[F] {
      def trace(msg: => String): F[Unit] =
        log.ftrace(msg)

      def debug(msg: => String): F[Unit] =
        log.fdebug(msg)

      def info(msg: => String): F[Unit] =
        log.finfo(msg)

      def warn(msg: => String): F[Unit] =
        log.fwarn(msg)

      def error(ex: Throwable)(msg: => String): F[Unit] =
        log.ferror(ex)(msg)

      def error(msg: => String): F[Unit] =
        log.ferror(msg)
    }

}
