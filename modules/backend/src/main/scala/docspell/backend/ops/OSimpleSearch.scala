/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.ops

import cats.Applicative
import cats.effect.Sync
import cats.implicits._

import docspell.backend.ops.OSimpleSearch._
import docspell.common._
import docspell.query._
import docspell.store.qb.Batch
import docspell.store.queries.Query
import docspell.store.queries.SearchSummary

import org.log4s.getLogger

/** A "porcelain" api on top of OFulltext and OItemSearch. This takes
  * care of restricting the items to a subset, e.g. only items that
  * have a "valid" state.
  */
trait OSimpleSearch[F[_]] {

  /** Search for items using the given query and optional fulltext
    * search.
    *
    * When using fulltext search only (the query is empty), only the
    * index is searched. It is assumed that the index doesn't contain
    * "invalid" items. When using a query, then a condition to select
    * only valid items is added to it.
    */
  def search(settings: Settings)(q: Query, fulltextQuery: Option[String]): F[Items]

  /** Using the same arguments as in `search`, this returns a summary
    * and not the results.
    */
  def searchSummary(
      useFTS: Boolean
  )(q: Query, fulltextQuery: Option[String]): F[SearchSummary]

  /** Calls `search` by parsing the given query string into a query that
    * is then amended wtih the given `fix` query.
    */
  final def searchByString(
      settings: Settings
  )(fix: Query.Fix, q: ItemQueryString)(implicit
      F: Applicative[F]
  ): F[StringSearchResult[Items]] =
    OSimpleSearch.applySearch[F, Items](fix, q)((iq, fts) => search(settings)(iq, fts))

  /** Same as `searchByString` but returning a summary instead of the
    * results.
    */
  final def searchSummaryByString(
      useFTS: Boolean
  )(fix: Query.Fix, q: ItemQueryString)(implicit
      F: Applicative[F]
  ): F[StringSearchResult[SearchSummary]] =
    OSimpleSearch.applySearch[F, SearchSummary](fix, q)((iq, fts) =>
      searchSummary(useFTS)(iq, fts)
    )
}

object OSimpleSearch {
  private[this] val logger = getLogger

  sealed trait StringSearchResult[+A]
  object StringSearchResult {
    case class ParseFailed(error: ParseFailure) extends StringSearchResult[Nothing]
    def parseFailed[A](error: ParseFailure): StringSearchResult[A] =
      ParseFailed(error)

    case class FulltextMismatch(error: FulltextExtract.FailureResult)
        extends StringSearchResult[Nothing]
    def fulltextMismatch[A](error: FulltextExtract.FailureResult): StringSearchResult[A] =
      FulltextMismatch(error)

    case class Success[A](value: A) extends StringSearchResult[A]
  }

  final case class Settings(
      batch: Batch,
      useFTS: Boolean,
      resolveDetails: Boolean,
      maxNoteLen: Int
  )

  sealed trait Items {
    def fold[A](
        f1: Items.FtsItems => A,
        f2: Items.FtsItemsFull => A,
        f3: Vector[OItemSearch.ListItem] => A,
        f4: Vector[OItemSearch.ListItemWithTags] => A
    ): A

  }
  object Items {
    def ftsItems(indexOnly: Boolean)(items: Vector[OFulltext.FtsItem]): Items =
      FtsItems(items, indexOnly)

    case class FtsItems(items: Vector[OFulltext.FtsItem], indexOnly: Boolean)
        extends Items {
      def fold[A](
          f1: FtsItems => A,
          f2: FtsItemsFull => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f1(this)

    }

    def ftsItemsFull(indexOnly: Boolean)(
        items: Vector[OFulltext.FtsItemWithTags]
    ): Items =
      FtsItemsFull(items, indexOnly)

    case class FtsItemsFull(items: Vector[OFulltext.FtsItemWithTags], indexOnly: Boolean)
        extends Items {
      def fold[A](
          f1: FtsItems => A,
          f2: FtsItemsFull => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f2(this)
    }

    def itemsPlain(items: Vector[OItemSearch.ListItem]): Items =
      ItemsPlain(items)

    case class ItemsPlain(items: Vector[OItemSearch.ListItem]) extends Items {
      def fold[A](
          f1: FtsItems => A,
          f2: FtsItemsFull => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f3(items)
    }

    def itemsFull(items: Vector[OItemSearch.ListItemWithTags]): Items =
      ItemsFull(items)

    case class ItemsFull(items: Vector[OItemSearch.ListItemWithTags]) extends Items {
      def fold[A](
          f1: FtsItems => A,
          f2: FtsItemsFull => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f4(items)
    }

  }

  def apply[F[_]: Sync](fts: OFulltext[F], is: OItemSearch[F]): OSimpleSearch[F] =
    new Impl(fts, is)

  /** Parses the query and calls `run` with the result, which searches items. */
  private def applySearch[F[_]: Applicative, A](fix: Query.Fix, q: ItemQueryString)(
      run: (Query, Option[String]) => F[A]
  ): F[StringSearchResult[A]] = {
    val parsed: Either[StringSearchResult[A], Option[ItemQuery]] =
      if (q.isEmpty) Right(None)
      else
        ItemQueryParser
          .parse(q.query)
          .leftMap(StringSearchResult.parseFailed)
          .map(_.some)

    def makeQuery(itemQuery: Option[ItemQuery]): F[StringSearchResult[A]] =
      runQuery[F, A](itemQuery) {
        case Some(s) =>
          run(Query(fix, Query.QueryExpr(s.getExprPart)), s.getFulltextPart)
        case None =>
          run(Query(fix), None)
      }

    parsed match {
      case Right(iq) =>
        makeQuery(iq)
      case Left(err) =>
        err.pure[F]
    }
  }

  /** Calls `run` with one of the success results when extracting the
    * fulltext search node from the query.
    */
  private def runQuery[F[_]: Applicative, A](
      itemQuery: Option[ItemQuery]
  )(run: Option[FulltextExtract.SuccessResult] => F[A]): F[StringSearchResult[A]] =
    itemQuery match {
      case Some(iq) =>
        iq.findFulltext match {
          case s: FulltextExtract.SuccessResult =>
            run(Some(s)).map(StringSearchResult.Success.apply)
          case other: FulltextExtract.FailureResult =>
            StringSearchResult.fulltextMismatch[A](other).pure[F]
        }
      case None =>
        run(None).map(StringSearchResult.Success.apply)
    }

  final class Impl[F[_]: Sync](fts: OFulltext[F], is: OItemSearch[F])
      extends OSimpleSearch[F] {

    /** Implements searching like this: it exploits the fact that teh
      * fulltext index only contains valid items. When searching via
      * sql the query expression selecting only valid items is added
      * here.
      */
    def search(
        settings: Settings
    )(q: Query, fulltextQuery: Option[String]): F[Items] = {
      // 1. fulltext only   if fulltextQuery.isDefined && q.isEmpty && useFTS
      // 2. sql+fulltext    if fulltextQuery.isDefined && q.nonEmpty && useFTS
      // 3. sql-only        else (if fulltextQuery.isEmpty || !useFTS)
      val validItemQuery = q.withFix(_.andQuery(ItemQuery.Expr.ValidItemStates))
      fulltextQuery match {
        case Some(ftq) if settings.useFTS =>
          if (q.isEmpty) {
            logger.debug(s"Using index only search: $fulltextQuery")
            fts
              .findIndexOnly(settings.maxNoteLen)(
                OFulltext.FtsInput(ftq),
                q.fix.account,
                settings.batch
              )
              .map(Items.ftsItemsFull(true))
          } else if (settings.resolveDetails) {
            logger.debug(
              s"Using index+sql search with tags: $validItemQuery / $fulltextQuery"
            )
            fts
              .findItemsWithTags(settings.maxNoteLen)(
                validItemQuery,
                OFulltext.FtsInput(ftq),
                settings.batch
              )
              .map(Items.ftsItemsFull(false))
          } else {
            logger.debug(
              s"Using index+sql search no tags: $validItemQuery / $fulltextQuery"
            )
            fts
              .findItems(settings.maxNoteLen)(
                validItemQuery,
                OFulltext.FtsInput(ftq),
                settings.batch
              )
              .map(Items.ftsItems(false))
          }
        case _ =>
          if (settings.resolveDetails) {
            logger.debug(
              s"Using sql only search with tags: $validItemQuery / $fulltextQuery"
            )
            is.findItemsWithTags(settings.maxNoteLen)(validItemQuery, settings.batch)
              .map(Items.itemsFull)
          } else {
            logger.debug(
              s"Using sql only search no tags: $validItemQuery / $fulltextQuery"
            )
            is.findItems(settings.maxNoteLen)(validItemQuery, settings.batch)
              .map(Items.itemsPlain)
          }
      }
    }

    def searchSummary(
        useFTS: Boolean
    )(q: Query, fulltextQuery: Option[String]): F[SearchSummary] = {
      val validItemQuery = q.withFix(_.andQuery(ItemQuery.Expr.ValidItemStates))
      fulltextQuery match {
        case Some(ftq) if useFTS =>
          if (q.isEmpty)
            fts.findIndexOnlySummary(q.fix.account, OFulltext.FtsInput(ftq))
          else
            fts
              .findItemsSummary(validItemQuery, OFulltext.FtsInput(ftq))

        case _ =>
          is.findItemsSummary(validItemQuery)
      }
    }
  }
}
