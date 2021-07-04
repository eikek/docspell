/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.records.{REquipment, RItem}
import docspell.store.{AddResult, Store}

trait OEquipment[F[_]] {

  def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[REquipment]]

  def find(account: AccountId, id: Ident): F[Option[REquipment]]

  def add(s: REquipment): F[AddResult]

  def update(s: REquipment): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]
}

object OEquipment {

  def apply[F[_]: Async](store: Store[F]): Resource[F, OEquipment[F]] =
    Resource.pure[F, OEquipment[F]](new OEquipment[F] {
      def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[REquipment]] =
        store.transact(REquipment.findAll(account.collective, nameQuery, _.name))

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
