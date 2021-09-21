/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.records.{REquipment, RItem}
import docspell.store.{AddResult, Store}

trait OEquipment[F[_]] {

  def findAll(
      account: AccountId,
      nameQuery: Option[String],
      order: OEquipment.EquipmentOrder
  ): F[Vector[REquipment]]

  def find(account: AccountId, id: Ident): F[Option[REquipment]]

  def add(s: REquipment): F[AddResult]

  def update(s: REquipment): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]
}

object OEquipment {
  import docspell.store.qb.DSL._

  sealed trait EquipmentOrder
  object EquipmentOrder {
    final case object NameAsc  extends EquipmentOrder
    final case object NameDesc extends EquipmentOrder

    def parse(str: String): Either[String, EquipmentOrder] =
      str.toLowerCase match {
        case "name"  => Right(NameAsc)
        case "-name" => Right(NameDesc)
        case _       => Left(s"Unknown sort property for equipments: $str")
      }

    def parseOrDefault(str: String): EquipmentOrder =
      parse(str).toOption.getOrElse(NameAsc)

    private[ops] def apply(order: EquipmentOrder)(table: REquipment.Table) = order match {
      case NameAsc  => NonEmptyList.of(table.name.asc)
      case NameDesc => NonEmptyList.of(table.name.desc)
    }
  }

  def apply[F[_]: Async](store: Store[F]): Resource[F, OEquipment[F]] =
    Resource.pure[F, OEquipment[F]](new OEquipment[F] {
      def findAll(
          account: AccountId,
          nameQuery: Option[String],
          order: EquipmentOrder
      ): F[Vector[REquipment]] =
        store.transact(
          REquipment.findAll(account.collective, nameQuery, EquipmentOrder(order))
        )

      def find(account: AccountId, id: Ident): F[Option[REquipment]] =
        store.transact(REquipment.findById(id)).map(_.filter(_.cid == account.collective))

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
