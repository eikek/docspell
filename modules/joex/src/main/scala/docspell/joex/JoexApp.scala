package docspell.joex

trait JoexApp[F[_]] {

  def init: F[Unit]
}
