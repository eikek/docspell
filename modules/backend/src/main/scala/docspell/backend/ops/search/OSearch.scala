/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops.search

import java.time.LocalDate

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import cats.{Functor, ~>}
import fs2.Stream

import docspell.common._
import docspell.ftsclient.{FtsClient, FtsQuery}
import docspell.query.{FulltextExtract, ItemQuery, ItemQueryParser}
import docspell.store.Store
import docspell.store.fts.RFtsResult
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
  def search(maxNoteLen: Int, today: Option[LocalDate], batch: Batch)(
      q: Query,
      fulltextQuery: Option[String]
  ): F[Vector[ListItem]]

  /** Same as `search` above, but runs additionally queries per item (!) to retrieve more
    * details.
    */
  def searchWithDetails(
      maxNoteLen: Int,
      today: Option[LocalDate],
      batch: Batch
  )(
      q: Query,
      fulltextQuery: Option[String]
  ): F[Vector[ListItemWithTags]]

  /** Selects either `search` or `searchWithDetails`. For the former the items are filled
    * with empty details.
    */
  final def searchSelect(
      withDetails: Boolean,
      maxNoteLen: Int,
      today: Option[LocalDate],
      batch: Batch
  )(
      q: Query,
      fulltextQuery: Option[String]
  )(implicit F: Functor[F]): F[Vector[ListItemWithTags]] =
    if (withDetails) searchWithDetails(maxNoteLen, today, batch)(q, fulltextQuery)
    else search(maxNoteLen, today, batch)(q, fulltextQuery).map(_.map(_.toWithTags))

  /** Run multiple database calls with the give query to collect a summary. */
  def searchSummary(
      today: Option[LocalDate]
  )(q: Query, fulltextQuery: Option[String]): F[SearchSummary]

  /** Parses a query string and creates a `Query` object, to be used with the other
    * methods. The query object contains the parsed query amended with more conditions,
    * for example to restrict to valid items only (as specified with `mode`). An empty
    * query string is allowed and returns a query containing only the restrictions in the
    * `q.fix` part.
    */
  def parseQueryString(
      accountId: AccountInfo,
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
      private[this] val logger = docspell.logging.getLogger[F]

      def parseQueryString(
          accountId: AccountInfo,
          mode: SearchMode,
          qs: String
      ): QueryParseResult = {
        val validItemQuery =
          mode match {
            case SearchMode.Trashed => ItemQuery.Expr.Trashed
            case SearchMode.Normal  => ItemQuery.Expr.ValidItemStates
            case SearchMode.All     => ItemQuery.Expr.ValidItemsOrTrashed
          }

        if (qs.trim.isEmpty) {
          val qf = Query.Fix(accountId, Some(validItemQuery), None)
          val qq = Query.QueryExpr(None)
          val q = Query(qf, qq)
          QueryParseResult.Success(q, None)
        } else
          ItemQueryParser.parse(qs) match {
            case Right(iq) =>
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
      }

      def search(maxNoteLen: Int, today: Option[LocalDate], batch: Batch)(
          q: Query,
          fulltextQuery: Option[String]
      ): F[Vector[ListItem]] =
        fulltextQuery match {
          case Some(ftq) =>
            for {
              timed <- Duration.stopTime[F]
              ftq <- createFtsQuery(q.fix.account, ftq)
              date <- OptionT
                .fromOption(today)
                .getOrElseF(Timestamp.current[F].map(_.toUtcDate))

              results <- WeakAsync.liftK[F, ConnectionIO].use { nat =>
                val tempTable = temporaryFtsTable(ftq, nat)
                store
                  .transact(
                    Stream
                      .eval(tempTable)
                      .flatMap(tt =>
                        QItem.queryItems(q, date, maxNoteLen, batch, tt.some)
                      )
                  )
                  .compile
                  .toVector
              }
              duration <- timed
              _ <- logger.debug(s"Simple search with fts in: ${duration.formatExact}")
            } yield results

          case None =>
            for {
              timed <- Duration.stopTime[F]
              date <- OptionT
                .fromOption(today)
                .getOrElseF(Timestamp.current[F].map(_.toUtcDate))
              results <- store
                .transact(QItem.queryItems(q, date, maxNoteLen, batch, None))
                .compile
                .toVector
              duration <- timed
              _ <- logger.debug(s"Simple search sql in: ${duration.formatExact}")
            } yield results
        }

      def searchWithDetails(
          maxNoteLen: Int,
          today: Option[LocalDate],
          batch: Batch
      )(
          q: Query,
          fulltextQuery: Option[String]
      ): F[Vector[ListItemWithTags]] =
        for {
          items <- search(maxNoteLen, today, batch)(q, fulltextQuery)
          timed <- Duration.stopTime[F]
          resolved <- store
            .transact(
              QItem.findItemsWithTags(q.fix.account.collectiveId, Stream.emits(items))
            )
            .compile
            .toVector
          duration <- timed
          _ <- logger.debug(s"Search: resolved details in: ${duration.formatExact}")
        } yield resolved

      def searchSummary(
          today: Option[LocalDate]
      )(q: Query, fulltextQuery: Option[String]): F[SearchSummary] =
        fulltextQuery match {
          case Some(ftq) =>
            for {
              ftq <- createFtsQuery(q.fix.account, ftq)
              date <- OptionT
                .fromOption(today)
                .getOrElseF(Timestamp.current[F].map(_.toUtcDate))
              results <- WeakAsync.liftK[F, ConnectionIO].use { nat =>
                val tempTable = temporaryFtsTable(ftq, nat)
                store.transact(
                  tempTable.flatMap(tt => QItem.searchStats(date, tt.some)(q))
                )
              }
            } yield results

          case None =>
            OptionT
              .fromOption(today)
              .getOrElseF(Timestamp.current[F].map(_.toUtcDate))
              .flatMap(date => store.transact(QItem.searchStats(date, None)(q)))
        }

      private def createFtsQuery(
          account: AccountInfo,
          ftq: String
      ): F[FtsQuery] =
        store
          .transact(QFolder.getMemberFolders(account.collectiveId, account.userId))
          .map(folders =>
            FtsQuery(ftq, account.collectiveId, 500, 0)
              .withFolders(folders)
          )

      def temporaryFtsTable(
          ftq: FtsQuery,
          nat: F ~> ConnectionIO
      ): ConnectionIO[RFtsResult.Table] =
        ftsClient
          .searchAll(ftq)
          .translate(nat)
          .through(RFtsResult.prepareTable(store.dbms, "fts_result"))
          .compile
          .lastOrError
    }
}
