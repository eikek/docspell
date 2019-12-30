package docspell.backend.ops

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.common.{AccountId, Ident}
import docspell.store.{AddResult, Store}
import docspell.store.records.{REquipment, RItem}

trait OEquipment[F[_]] {

  def findAll(account: AccountId): F[Vector[REquipment]]

  def add(s: REquipment): F[AddResult]

  def update(s: REquipment): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]
}

object OEquipment {

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OEquipment[F]] =
    Resource.pure(new OEquipment[F] {
      def findAll(account: AccountId): F[Vector[REquipment]] =
        store.transact(REquipment.findAll(account.collective, _.name))

      def add(e: REquipment): F[AddResult] = {
        def insert = REquipment.insert(e)
        def exists = REquipment.existsByName(e.cid, e.name)

        val msg = s"An equipment '${e.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def update(e: REquipment): F[AddResult] = {
        def insert = REquipment.update(e)
        def exists = REquipment.existsByName(e.cid, e.name)

        val msg = s"An equipment '${e.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def delete(id: Ident, collective: Ident): F[AddResult] = {
        val io = for {
          n0 <- RItem.removeConcEquip(collective, id)
          n1 <- REquipment.delete(id, collective)
        } yield n0 + n1
        store.transact(io).attempt.map(AddResult.fromUpdate)
      }
    })
}
