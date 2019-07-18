package docspell.restserver

trait RestApp[F[_]] {

  def init: F[Unit]
}
