package docspell.restserver

import docspell.backend.BackendApp

trait RestApp[F[_]] {

  def init: F[Unit]

  def config: Config

  def backend: BackendApp[F]
}
