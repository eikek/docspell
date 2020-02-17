package docspell.common

trait Logger[F[_]] {

  def trace(msg: => String): F[Unit]
  def debug(msg: => String): F[Unit]
  def info(msg: => String): F[Unit]
  def warn(msg: => String): F[Unit]
  def error(ex: Throwable)(msg: => String): F[Unit]
  def error(msg: => String): F[Unit]

}
