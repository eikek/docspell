package docspell.joex

import cats.data.Kleisli

package object fts {

  type FtsWork[F[_]] = Kleisli[F, FtsContext[F], Unit]

}
