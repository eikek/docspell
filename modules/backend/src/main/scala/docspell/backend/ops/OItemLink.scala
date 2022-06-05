/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItemLink.LinkResult
import docspell.backend.ops.search.OSearch
import docspell.common.{AccountId, Ident}
import docspell.query.ItemQuery
import docspell.query.ItemQueryDsl._
import docspell.store.qb.Batch
import docspell.store.queries.{ListItemWithTags, Query}
import docspell.store.records.RItemLink
import docspell.store.{AddResult, Store}

trait OItemLink[F[_]] {

  def addAll(cid: Ident, target: Ident, related: NonEmptyList[Ident]): F[LinkResult]

  def removeAll(cid: Ident, target: Ident, related: NonEmptyList[Ident]): F[Unit]

  def getRelated(
      account: AccountId,
      item: Ident,
      batch: Batch
  ): F[Vector[ListItemWithTags]]
}

object OItemLink {

  sealed trait LinkResult
  object LinkResult {

    /** When the target item is in the related list. */
    case object LinkTargetItemError extends LinkResult
    case object Success extends LinkResult

    def linkTargetItemError: LinkResult = LinkTargetItemError
  }

  def apply[F[_]: Sync](store: Store[F], search: OSearch[F]): OItemLink[F] =
    new OItemLink[F] {
      def getRelated(
          accountId: AccountId,
          item: Ident,
          batch: Batch
      ): F[Vector[ListItemWithTags]] =
        store
          .transact(RItemLink.findLinked(accountId.collective, item))
          .map(ids => NonEmptyList.fromList(ids.toList))
          .flatMap {
            case Some(nel) =>
              val expr = Q.itemIdsIn(nel.map(_.id))
              val query = Query(
                Query
                  .Fix(accountId, Some(ItemQuery.Expr.ValidItemStates), None),
                Query.QueryExpr(expr)
              )
              search.searchWithDetails(0, None, batch)(query, None)

            case None =>
              Vector.empty[ListItemWithTags].pure[F]
          }

      def addAll(cid: Ident, target: Ident, related: NonEmptyList[Ident]): F[LinkResult] =
        if (related.contains_(target)) LinkResult.linkTargetItemError.pure[F]
        else related.traverse(addSingle(cid, target, _)).as(LinkResult.Success)

      def removeAll(cid: Ident, target: Ident, related: NonEmptyList[Ident]): F[Unit] =
        store.transact(RItemLink.deleteAll(cid, target, related)).void

      def addSingle(cid: Ident, target: Ident, related: Ident): F[Unit] = {
        val exists = RItemLink.exists(cid, target, related)
        val insert = RItemLink.insertNew(cid, target, related)
        store.add(insert, exists).flatMap {
          case AddResult.Success         => ().pure[F]
          case AddResult.EntityExists(_) => ().pure[F]
          case AddResult.Failure(ex) =>
            Sync[F].raiseError(ex)
        }
      }
    }
}
