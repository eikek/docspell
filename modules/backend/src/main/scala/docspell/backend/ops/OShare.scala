/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.PasswordCrypt
import docspell.common._
import docspell.query.ItemQuery
import docspell.store.Store
import docspell.store.records.RShare

trait OShare[F[_]] {

  def findAll(collective: Ident): F[List[RShare]]

  def delete(id: Ident, collective: Ident): F[Boolean]

  def addNew(share: OShare.NewShare): F[OShare.ChangeResult]

  def findOne(id: Ident, collective: Ident): OptionT[F, RShare]

  def update(
      id: Ident,
      share: OShare.NewShare,
      removePassword: Boolean
  ): F[OShare.ChangeResult]
}

object OShare {

  final case class NewShare(
      cid: Ident,
      name: Option[String],
      query: ItemQuery,
      enabled: Boolean,
      password: Option[Password],
      publishUntil: Timestamp
  )

  sealed trait ChangeResult
  object ChangeResult {
    final case class Success(id: Ident) extends ChangeResult
    case object PublishUntilInPast extends ChangeResult

    def success(id: Ident): ChangeResult = Success(id)
    def publishUntilInPast: ChangeResult = PublishUntilInPast
  }

  def apply[F[_]: Async](store: Store[F]): OShare[F] =
    new OShare[F] {
      def findAll(collective: Ident): F[List[RShare]] =
        store.transact(RShare.findAllByCollective(collective))

      def delete(id: Ident, collective: Ident): F[Boolean] =
        store.transact(RShare.deleteByIdAndCid(id, collective)).map(_ > 0)

      def addNew(share: NewShare): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          id <- Ident.randomId[F]
          pass = share.password.map(PasswordCrypt.crypt)
          record = RShare(
            id,
            share.cid,
            share.name,
            share.query,
            share.enabled,
            pass,
            curTime,
            share.publishUntil,
            0,
            None
          )
          res <-
            if (share.publishUntil < curTime) ChangeResult.publishUntilInPast.pure[F]
            else store.transact(RShare.insert(record)).map(_ => ChangeResult.success(id))
        } yield res

      def update(
          id: Ident,
          share: OShare.NewShare,
          removePassword: Boolean
      ): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          record = RShare(
            id,
            share.cid,
            share.name,
            share.query,
            share.enabled,
            share.password.map(PasswordCrypt.crypt),
            Timestamp.Epoch,
            share.publishUntil,
            0,
            None
          )
          res <-
            if (share.publishUntil < curTime) ChangeResult.publishUntilInPast.pure[F]
            else
              store
                .transact(RShare.updateData(record, removePassword))
                .map(_ => ChangeResult.success(id))
        } yield res

      def findOne(id: Ident, collective: Ident): OptionT[F, RShare] =
        RShare.findOne(id, collective).mapK(store.transform)
    }
}
