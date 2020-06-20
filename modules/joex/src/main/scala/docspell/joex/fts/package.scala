package docspell.joex

import cats.data.Kleisli

package object fts {

  type MigrationTask[F[_]] = Kleisli[F, MigrateCtx[F], Unit]

}
