package docspell.backend.ops

import cats.effect.{Effect, Resource}

import docspell.common._
import docspell.store.Store
import docspell.store.records.RCustomField

trait OCustomFields[F[_]] {

  def findAll(coll: Ident): F[Vector[RCustomField]]

}

object OCustomFields {

  def apply[F[_]: Effect](
      store: Store[F]
  ): Resource[F, OCustomFields[F]] =
    Resource.pure[F, OCustomFields[F]](new OCustomFields[F] {

      def findAll(coll: Ident): F[Vector[RCustomField]] =
        store.transact(RCustomField.findAll(coll))
    })
}
