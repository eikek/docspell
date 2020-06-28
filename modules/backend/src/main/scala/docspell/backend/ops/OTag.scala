package docspell.backend.ops

import cats.effect.{Effect, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.records.{RTag, RTagItem}
import docspell.store.{AddResult, Store}

trait OTag[F[_]] {

  def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[RTag]]

  def add(s: RTag): F[AddResult]

  def update(s: RTag): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]

  /** Load all tags given their ids. Ids that are not available are ignored.
    */
  def loadAll(ids: List[Ident]): F[Vector[RTag]]
}

object OTag {

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OTag[F]] =
    Resource.pure[F, OTag[F]](new OTag[F] {
      def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[RTag]] =
        store.transact(RTag.findAll(account.collective, nameQuery, _.name))

      def add(t: RTag): F[AddResult] = {
        def insert = RTag.insert(t)
        def exists = RTag.existsByName(t)

        val msg = s"A tag '${t.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def update(t: RTag): F[AddResult] = {
        def insert = RTag.update(t)
        def exists = RTag.existsByName(t)

        val msg = s"A tag '${t.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def delete(id: Ident, collective: Ident): F[AddResult] = {
        val io = for {
          optTag <- RTag.findByIdAndCollective(id, collective)
          n0     <- optTag.traverse(t => RTagItem.deleteTag(t.tagId))
          n1     <- optTag.traverse(t => RTag.delete(t.tagId, collective))
        } yield n0.getOrElse(0) + n1.getOrElse(0)
        store.transact(io).attempt.map(AddResult.fromUpdate)
      }

      def loadAll(ids: List[Ident]): F[Vector[RTag]] =
        if (ids.isEmpty) Vector.empty.pure[F]
        else store.transact(RTag.findAllById(ids))
    })
}
