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
import docspell.store.records._

trait OQueryBookmarks[F[_]] {

  def getAll(account: AccountInfo): F[Vector[OQueryBookmarks.Bookmark]]

  def findOne(account: AccountInfo, nameOrId: String): F[Option[OQueryBookmarks.Bookmark]]

  def create(account: AccountInfo, bookmark: OQueryBookmarks.NewBookmark): F[AddResult]

  def update(
      account: AccountInfo,
      id: Ident,
      bookmark: OQueryBookmarks.NewBookmark
  ): F[UpdateResult]

  def delete(account: AccountInfo, bookmark: Ident): F[Unit]
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
      def getAll(account: AccountInfo): F[Vector[Bookmark]] =
        store
          .transact(RQueryBookmark.allForUser(account.collectiveId, account.userId))
          .map(_.map(convert.toModel))

      def findOne(
          account: AccountInfo,
          nameOrId: String
      ): F[Option[OQueryBookmarks.Bookmark]] =
        store
          .transact(
            RQueryBookmark.findByNameOrId(account.collectiveId, account.userId, nameOrId)
          )
          .map(_.map(convert.toModel))

      def create(account: AccountInfo, b: NewBookmark): F[AddResult] = {
        val uid = if (b.personal) account.userId.some else None
        val record =
          RQueryBookmark.createNew(
            account.collectiveId,
            uid,
            b.name,
            b.label,
            b.query
          )
        store.transact(
          RQueryBookmark.insertIfNotExists(account.collectiveId, account.userId, record)
        )
      }

      def update(acc: AccountInfo, id: Ident, b: NewBookmark): F[UpdateResult] =
        UpdateResult.fromUpdate(
          store.transact(RQueryBookmark.update(convert.toRecord(acc, id, b)))
        )

      def delete(account: AccountInfo, bookmark: Ident): F[Unit] =
        store.transact(RQueryBookmark.deleteById(account.collectiveId, bookmark)).as(())
    })

  private object convert {

    def toModel(r: RQueryBookmark): Bookmark =
      Bookmark(r.id, r.name, r.label, r.query, r.isPersonal, r.created)

    def toRecord(
        account: AccountInfo,
        id: Ident,
        b: NewBookmark
    ): RQueryBookmark =
      RQueryBookmark(
        id,
        b.name,
        b.label,
        if (b.personal) account.userId.some else None,
        account.collectiveId,
        b.query,
        Timestamp.Epoch
      )

  }
}
