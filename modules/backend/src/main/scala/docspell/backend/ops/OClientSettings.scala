/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.AccountId
import docspell.common._
import docspell.store.Store
import docspell.store.records.RClientSettingsCollective
import docspell.store.records.RClientSettingsUser
import docspell.store.records.RUser

import io.circe.Json

trait OClientSettings[F[_]] {

  def deleteUser(clientId: Ident, account: AccountId): F[Boolean]
  def saveUser(clientId: Ident, account: AccountId, data: Json): F[Unit]
  def loadUser(clientId: Ident, account: AccountId): F[Option[RClientSettingsUser]]

  def deleteCollective(clientId: Ident, account: AccountId): F[Boolean]
  def saveCollective(clientId: Ident, account: AccountId, data: Json): F[Unit]
  def loadCollective(
      clientId: Ident,
      account: AccountId
  ): F[Option[RClientSettingsCollective]]

}

object OClientSettings {
  private[this] val logger = org.log4s.getLogger

  def apply[F[_]: Async](store: Store[F]): Resource[F, OClientSettings[F]] =
    Resource.pure[F, OClientSettings[F]](new OClientSettings[F] {
      val log = Logger.log4s[F](logger)

      private def getUserId(account: AccountId): OptionT[F, Ident] =
        OptionT(store.transact(RUser.findByAccount(account))).map(_.uid)

      def deleteCollective(clientId: Ident, account: AccountId): F[Boolean] =
        store
          .transact(RClientSettingsCollective.delete(clientId, account.collective))
          .map(_ > 0)

      def deleteUser(clientId: Ident, account: AccountId): F[Boolean] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Deleting client settings for client ${clientId.id} and account $account"
            )
          )
          userId <- getUserId(account)
          n <- OptionT.liftF(
            store.transact(
              RClientSettingsUser.delete(clientId, userId)
            )
          )
        } yield n > 0).getOrElse(false)

      def saveCollective(clientId: Ident, account: AccountId, data: Json): F[Unit] =
        for {
          n <- store.transact(
            RClientSettingsCollective.upsert(clientId, account.collective, data)
          )
          _ <-
            if (n <= 0) Async[F].raiseError(new IllegalStateException("No rows updated!"))
            else ().pure[F]
        } yield ()

      def saveUser(clientId: Ident, account: AccountId, data: Json): F[Unit] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Storing client settings for client ${clientId.id} and account $account"
            )
          )
          userId <- getUserId(account)
          n <- OptionT.liftF(
            store.transact(RClientSettingsUser.upsert(clientId, userId, data))
          )
          _ <- OptionT.liftF(
            if (n <= 0) Async[F].raiseError(new Exception("No rows updated!"))
            else ().pure[F]
          )
        } yield ()).getOrElse(())

      def loadCollective(
          clientId: Ident,
          account: AccountId
      ): F[Option[RClientSettingsCollective]] =
        store.transact(RClientSettingsCollective.find(clientId, account.collective))

      def loadUser(clientId: Ident, account: AccountId): F[Option[RClientSettingsUser]] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Loading client settings for client ${clientId.id} and account $account"
            )
          )
          userId <- getUserId(account)
          data <- OptionT(store.transact(RClientSettingsUser.find(clientId, userId)))
        } yield data).value

    })
}
