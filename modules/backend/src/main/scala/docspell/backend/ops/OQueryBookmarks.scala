/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.AddResult
import docspell.store.Store
import docspell.store.UpdateResult
import docspell.store.records.RQueryBookmark

trait OQueryBookmarks[F[_]] {

  def getAll(account: AccountId): F[Vector[OQueryBookmarks.Bookmark]]

  def create(account: AccountId, bookmark: OQueryBookmarks.NewBookmark): F[AddResult]

  def update(
      account: AccountId,
      id: Ident,
      bookmark: OQueryBookmarks.NewBookmark
  ): F[UpdateResult]

  def delete(account: AccountId, bookmark: Ident): F[Unit]
}

object OQueryBookmarks {
  final case class NewBookmark(
      name: String,
      label: Option[String],
      query: ItemQuery,
      personal: Boolean
  )

  final case class Bookmark(
      id: Ident,
      name: String,
      label: Option[String],
      query: ItemQuery,
      personal: Boolean,
      created: Timestamp
  )

  def apply[F[_]: Sync](store: Store[F]): Resource[F, OQueryBookmarks[F]] =
    Resource.pure(new OQueryBookmarks[F] {
      def getAll(account: AccountId): F[Vector[Bookmark]] =
        store
          .transact(RQueryBookmark.allForUser(account))
          .map(
            _.map(r => Bookmark(r.id, r.name, r.label, r.query, r.isPersonal, r.created))
          )

      def create(account: AccountId, b: NewBookmark): F[AddResult] =
        store
          .transact(for {
            r <- RQueryBookmark.createNew(account, b.name, b.label, b.query, b.personal)
            n <- RQueryBookmark.insert(r)
          } yield n)
          .attempt
          .map(AddResult.fromUpdate)

      def update(account: AccountId, id: Ident, b: NewBookmark): F[UpdateResult] =
        UpdateResult.fromUpdate(
          store.transact(
            RQueryBookmark.update(
              RQueryBookmark(
                id,
                b.name,
                b.label,
                None, // userId and some other values are not used
                account.collective,
                b.query,
                Timestamp.Epoch
              )
            )
          )
        )

      def delete(account: AccountId, bookmark: Ident): F[Unit] =
        store.transact(RQueryBookmark.deleteById(account.collective, bookmark)).as(())

    })
}
