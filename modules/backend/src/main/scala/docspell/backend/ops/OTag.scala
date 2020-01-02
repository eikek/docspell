package docspell.backend.ops

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.common.{AccountId, Ident}
import docspell.store.{AddResult, Store}
import docspell.store.records.{RTag, RTagItem}

trait OTag[F[_]] {

  def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[RTag]]

  def add(s: RTag): F[AddResult]

  def update(s: RTag): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]
}

object OTag {

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OTag[F]] =
    Resource.pure(new OTag[F] {
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
    })
}
