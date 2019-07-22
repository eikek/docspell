package docspell.common.syntax

import cats.effect.Sync
import fs2.Stream
import org.log4s.Logger

trait LoggerSyntax {

  implicit final class LoggerOps(logger: Logger) {

    def ftrace[F[_]: Sync](msg: => String): F[Unit] =
      Sync[F].delay(logger.trace(msg))

    def fdebug[F[_]: Sync](msg: => String): F[Unit] =
      Sync[F].delay(logger.debug(msg))

    def sdebug[F[_]: Sync](msg: => String): Stream[F, Nothing] =
      Stream.eval(fdebug(msg)).drain

    def finfo[F[_]: Sync](msg: => String): F[Unit] =
      Sync[F].delay(logger.info(msg))

    def sinfo[F[_]: Sync](msg: => String): Stream[F, Nothing] =
      Stream.eval(finfo(msg)).drain

    def fwarn[F[_]: Sync](msg: => String): F[Unit] =
      Sync[F].delay(logger.warn(msg))

    def ferror[F[_]: Sync](msg: => String): F[Unit] =
      Sync[F].delay(logger.error(msg))

    def ferror[F[_]: Sync](ex: Throwable)(msg: => String): F[Unit] =
      Sync[F].delay(logger.error(ex)(msg))
  }
}
