/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.Semigroup
import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common._
import docspell.store.Store
import docspell.store.records.RClientSettingsCollective
import docspell.store.records.RClientSettingsUser

import io.circe.Json

trait OClientSettings[F[_]] {

  def deleteUser(clientId: Ident, userId: Ident): F[Boolean]
  def saveUser(clientId: Ident, userId: Ident, data: Json): F[Unit]
  def loadUser(clientId: Ident, userId: Ident): F[Option[RClientSettingsUser]]

  def deleteCollective(clientId: Ident, collectiveId: CollectiveId): F[Boolean]
  def saveCollective(clientId: Ident, collectiveId: CollectiveId, data: Json): F[Unit]
  def loadCollective(
      clientId: Ident,
      collectiveId: CollectiveId
  ): F[Option[RClientSettingsCollective]]

  def loadMerged(
      clientId: Ident,
      collectiveId: CollectiveId,
      userId: Ident
  ): F[Option[Json]]
}

object OClientSettings {
  def apply[F[_]: Async](store: Store[F]): Resource[F, OClientSettings[F]] =
    Resource.pure[F, OClientSettings[F]](new OClientSettings[F] {
      val log = docspell.logging.getLogger[F]

      def deleteCollective(clientId: Ident, collectiveId: CollectiveId): F[Boolean] =
        store
          .transact(RClientSettingsCollective.delete(clientId, collectiveId))
          .map(_ > 0)

      def deleteUser(clientId: Ident, userId: Ident): F[Boolean] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Deleting client settings for client ${clientId.id} and user ${userId.id}"
            )
          )
          n <- OptionT.liftF(
            store.transact(
              RClientSettingsUser.delete(clientId, userId)
            )
          )
        } yield n > 0).getOrElse(false)

      def saveCollective(
          clientId: Ident,
          collectiveId: CollectiveId,
          data: Json
      ): F[Unit] =
        for {
          n <- store.transact(
            RClientSettingsCollective.upsert(clientId, collectiveId, data)
          )
          _ <-
            if (n <= 0) Async[F].raiseError(new IllegalStateException("No rows updated!"))
            else ().pure[F]
        } yield ()

      def saveUser(clientId: Ident, userId: Ident, data: Json): F[Unit] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Storing client settings for client ${clientId.id} and user ${userId.id}"
            )
          )
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
          collectiveId: CollectiveId
      ): F[Option[RClientSettingsCollective]] =
        store.transact(RClientSettingsCollective.find(clientId, collectiveId))

      def loadUser(clientId: Ident, userId: Ident): F[Option[RClientSettingsUser]] =
        (for {
          _ <- OptionT.liftF(
            log.debug(
              s"Loading client settings for client ${clientId.id} and user ${userId.id}"
            )
          )
          data <- OptionT(store.transact(RClientSettingsUser.find(clientId, userId)))
        } yield data).value

      def loadMerged(clientId: Ident, collectiveId: CollectiveId, userId: Ident) =
        for {
          collData <- loadCollective(clientId, collectiveId)
          userData <- loadUser(clientId, userId)
          mergedData = collData.map(_.settingsData) |+| userData.map(_.settingsData)
        } yield mergedData

      implicit def jsonSemigroup: Semigroup[Json] =
        Semigroup.instance((a1, a2) => a1.deepMerge(a2))
    })
}
