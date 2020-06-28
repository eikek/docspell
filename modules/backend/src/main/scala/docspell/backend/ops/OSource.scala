package docspell.backend.ops

import cats.effect.{Effect, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.records.RSource
import docspell.store.{AddResult, Store}

trait OSource[F[_]] {

  def findAll(account: AccountId): F[Vector[RSource]]

  def add(s: RSource): F[AddResult]

  def update(s: RSource): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]
}

object OSource {

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OSource[F]] =
    Resource.pure[F, OSource[F]](new OSource[F] {
      def findAll(account: AccountId): F[Vector[RSource]] =
        store.transact(RSource.findAll(account.collective, _.abbrev))

      def add(s: RSource): F[AddResult] = {
        def insert = RSource.insert(s)
        def exists = RSource.existsByAbbrev(s.cid, s.abbrev)

        val msg = s"A source with abbrev '${s.abbrev}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def update(s: RSource): F[AddResult] = {
        def insert = RSource.updateNoCounter(s)
        def exists = RSource.existsByAbbrev(s.cid, s.abbrev)

        val msg = s"A source with abbrev '${s.abbrev}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def delete(id: Ident, collective: Ident): F[AddResult] =
        store.transact(RSource.delete(id, collective)).attempt.map(AddResult.fromUpdate)
    })
}
