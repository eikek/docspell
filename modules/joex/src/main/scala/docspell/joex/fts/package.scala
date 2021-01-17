package docspell.joex

import cats.data.Kleisli

package object fts {

  /** Some work that must be done to advance the schema of the fulltext
    * index.
    */
  type FtsWork[F[_]] = Kleisli[F, FtsContext[F], Unit]

}
