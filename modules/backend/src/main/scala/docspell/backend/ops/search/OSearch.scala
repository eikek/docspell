/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops.search

import java.time.LocalDate

import cats.effect._
import cats.syntax.all._
import cats.~>
import fs2.Stream

import docspell.backend.ops.OItemSearch.{ListItemWithTags, SearchSummary}
import docspell.common.{AccountId, SearchMode}
import docspell.ftsclient.{FtsClient, FtsQuery}
import docspell.query.{FulltextExtract, ItemQuery, ItemQueryParser}
import docspell.store.Store
import docspell.store.impl.TempFtsTable
import docspell.store.qb.Batch
import docspell.store.queries._

import doobie.{ConnectionIO, WeakAsync}

/** Combine fulltext search and sql search into one operation.
  *
  * To allow for paging the results from fulltext search are brought into the sql database
  * by creating a temporary table.
  */
trait OSearch[F[_]] {

  /** Searches at sql database with the given query joining it optionally with results
    * from fulltext search. Any "fulltext search" query node is discarded. It is assumed
    * that the fulltext search node has been extracted into the argument.
    */
  def search(maxNoteLen: Int, today: LocalDate, batch: Batch)(
      q: Query,
      fulltextQuery: Option[String]
  ): F[Vector[ListItem]]

  /** Same as `search` above, but runs additionally queries per item (!) to retrieve more
    * details.
    */
  def searchWithDetails(
      maxNoteLen: Int,
      today: LocalDate,
      batch: Batch
  )(
      q: Query,
      fulltextQuery: Option[String]
  ): F[Vector[ListItemWithTags]]

  /** Run multiple database calls with the give query to collect a summary. */
  def searchSummary(
      mode: SearchMode,
      today: LocalDate
  )(q: Query, fulltextQuery: Option[String]): F[SearchSummary]

  /** Parses a query string and creates a `Query` object, to be used with the other
    * methods. The query object contains the parsed query amended with more conditions to
    * restrict to valid items only (as specified with `mode`).
    */
  def parseQueryString(
      accountId: AccountId,
      mode: SearchMode,
      qs: String
  ): QueryParseResult
}

object OSearch {
  def apply[F[_]: Async](
      store: Store[F],
      ftsClient: FtsClient[F]
  ): OSearch[F] =
    new OSearch[F] {

      def parseQueryString(
          accountId: AccountId,
          mode: SearchMode,
          qs: String
      ): QueryParseResult =
        ItemQueryParser.parse(qs) match {
          case Right(iq) =>
            val validItemQuery =
              mode match {
                case SearchMode.Trashed => ItemQuery.Expr.Trashed
                case SearchMode.Normal  => ItemQuery.Expr.ValidItemStates
                case SearchMode.All     => ItemQuery.Expr.ValidItemsOrTrashed
              }
            FulltextExtract.findFulltext(iq.expr) match {
              case FulltextExtract.Result.SuccessNoFulltext(expr) =>
                val qf = Query.Fix(accountId, Some(validItemQuery), None)
                val qq = Query.QueryExpr(expr)
                val q = Query(qf, qq)
                QueryParseResult.Success(q, None)

              case FulltextExtract.Result.SuccessNoExpr(fts) =>
                val qf = Query.Fix(accountId, Some(validItemQuery), Option(_.byScore))
                val qq = Query.QueryExpr(None)
                val q = Query(qf, qq)
                QueryParseResult.Success(q, Some(fts))

              case FulltextExtract.Result.SuccessBoth(expr, fts) =>
                val qf = Query.Fix(accountId, Some(validItemQuery), None)
                val qq = Query.QueryExpr(expr)
                val q = Query(qf, qq)
                QueryParseResult.Success(q, Some(fts))

              case f: FulltextExtract.FailureResult =>
                QueryParseResult.FulltextMismatch(f)
            }

          case Left(err) =>
            QueryParseResult.ParseFailed(err).cast
        }

      def search(maxNoteLen: Int, today: LocalDate, batch: Batch)(
          q: Query,
          fulltextQuery: Option[String]
      ): F[Vector[ListItem]] =
        fulltextQuery match {
          case Some(ftq) =>
            for {
              ftq <- createFtsQuery(q.fix.account, batch, ftq)

              results <- WeakAsync.liftK[F, ConnectionIO].use { nat =>
                val tempTable = temporaryFtsTable(ftq, nat)
                store
                  .transact(
                    Stream
                      .eval(tempTable)
                      .flatMap(tt =>
                        QItem.queryItems(q, today, maxNoteLen, batch, tt.some)
                      )
                  )
                  .compile
                  .toVector
              }

            } yield results

          case None =>
            store
              .transact(QItem.queryItems(q, today, maxNoteLen, batch, None))
              .compile
              .toVector
        }

      def searchWithDetails(
          maxNoteLen: Int,
          today: LocalDate,
          batch: Batch
      )(
          q: Query,
          fulltextQuery: Option[String]
      ): F[Vector[ListItemWithTags]] =
        for {
          items <- search(maxNoteLen, today, batch)(q, fulltextQuery)
          resolved <- store
            .transact(
              QItem.findItemsWithTags(q.fix.account.collective, Stream.emits(items))
            )
            .compile
            .toVector
        } yield resolved

      def searchSummary(
          mode: SearchMode,
          today: LocalDate
      )(q: Query, fulltextQuery: Option[String]): F[SearchSummary] =
        fulltextQuery match {
          case Some(ftq) =>
            for {
              ftq <- createFtsQuery(q.fix.account, Batch.limit(500), ftq)
              results <- WeakAsync.liftK[F, ConnectionIO].use { nat =>
                val tempTable = temporaryFtsTable(ftq, nat)
                store.transact(
                  tempTable.flatMap(tt => QItem.searchStats(today, tt.some)(q))
                )
              }
            } yield results

          case None =>
            store.transact(QItem.searchStats(today, None)(q))
        }

      private def createFtsQuery(
          account: AccountId,
          batch: Batch,
          ftq: String
      ): F[FtsQuery] =
        store
          .transact(QFolder.getMemberFolders(account))
          .map(folders =>
            FtsQuery(ftq, account.collective, batch.limit, batch.offset)
              .withFolders(folders)
          )

      def temporaryFtsTable(
          ftq: FtsQuery,
          nat: F ~> ConnectionIO
      ): ConnectionIO[TempFtsTable.Table] =
        ftsClient
          .searchAll(ftq)
          .translate(nat)
          .through(TempFtsTable.prepareTable(store.dbms, "fts_result"))
          .compile
          .lastOrError
    }
}
