package docspell.backend.ops

import cats.effect.Sync
import cats.implicits._

import docspell.backend.ops.OSimpleSearch._
import docspell.common._
import docspell.query._
import docspell.store.qb.Batch
import docspell.store.queries.Query
import docspell.store.queries.SearchSummary

/** A "porcelain" api on top of OFulltext and OItemSearch. */
trait OSimpleSearch[F[_]] {

  def search(settings: Settings)(q: Query, fulltextQuery: Option[String]): F[Items]
  def searchSummary(
      useFTS: Boolean
  )(q: Query, fulltextQuery: Option[String]): F[SearchSummary]

  def searchByString(
      settings: Settings
  )(fix: Query.Fix, q: ItemQueryString): F[StringSearchResult[Items]]
  def searchSummaryByString(
      useFTS: Boolean
  )(fix: Query.Fix, q: ItemQueryString): F[StringSearchResult[SearchSummary]]

}

object OSimpleSearch {

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

  final class Impl[F[_]: Sync](fts: OFulltext[F], is: OItemSearch[F])
      extends OSimpleSearch[F] {
    def searchByString(
        settings: Settings
    )(fix: Query.Fix, q: ItemQueryString): F[StringSearchResult[Items]] = {
      val parsed: Either[StringSearchResult[Items], ItemQuery] =
        ItemQueryParser.parse(q.query).leftMap(StringSearchResult.parseFailed)

      def makeQuery(iq: ItemQuery): F[StringSearchResult[Items]] =
        iq.findFulltext match {
          case FulltextExtract.Result.Success(expr, ftq) =>
            search(settings)(Query(fix, Query.QueryExpr(iq.copy(expr = expr))), ftq)
              .map(StringSearchResult.Success.apply)
          case other: FulltextExtract.FailureResult =>
            StringSearchResult.fulltextMismatch[Items](other).pure[F]
        }

      parsed match {
        case Right(iq) =>
          makeQuery(iq)
        case Left(err) =>
          err.pure[F]
      }
    }

    def searchSummaryByString(
        useFTS: Boolean
    )(fix: Query.Fix, q: ItemQueryString): F[StringSearchResult[SearchSummary]] = {
      val parsed: Either[StringSearchResult[SearchSummary], ItemQuery] =
        ItemQueryParser.parse(q.query).leftMap(StringSearchResult.parseFailed)

      def makeQuery(iq: ItemQuery): F[StringSearchResult[SearchSummary]] =
        iq.findFulltext match {
          case FulltextExtract.Result.Success(expr, ftq) =>
            searchSummary(useFTS)(Query(fix, Query.QueryExpr(iq.copy(expr = expr))), ftq)
              .map(StringSearchResult.Success.apply)
          case other: FulltextExtract.FailureResult =>
            StringSearchResult.fulltextMismatch[SearchSummary](other).pure[F]
        }

      parsed match {
        case Right(iq) =>
          makeQuery(iq)
        case Left(err) =>
          err.pure[F]
      }
    }

    def searchSummary(
        useFTS: Boolean
    )(q: Query, fulltextQuery: Option[String]): F[SearchSummary] =
      fulltextQuery match {
        case Some(ftq) if useFTS =>
          if (q.isEmpty)
            fts.findIndexOnlySummary(q.fix.account, OFulltext.FtsInput(ftq))
          else
            fts
              .findItemsSummary(q, OFulltext.FtsInput(ftq))

        case _ =>
          is.findItemsSummary(q)
      }

    def search(settings: Settings)(q: Query, fulltextQuery: Option[String]): F[Items] =
      // 1. fulltext only   if fulltextQuery.isDefined && q.isEmpty && useFTS
      // 2. sql+fulltext    if fulltextQuery.isDefined && q.nonEmpty && useFTS
      // 3. sql-only        else (if fulltextQuery.isEmpty || !useFTS)
      fulltextQuery match {
        case Some(ftq) if settings.useFTS =>
          if (q.isEmpty)
            fts
              .findIndexOnly(settings.maxNoteLen)(
                OFulltext.FtsInput(ftq),
                q.fix.account,
                settings.batch
              )
              .map(Items.ftsItemsFull(true))
          else if (settings.resolveDetails)
            fts
              .findItemsWithTags(settings.maxNoteLen)(
                q,
                OFulltext.FtsInput(ftq),
                settings.batch
              )
              .map(Items.ftsItemsFull(false))
          else
            fts
              .findItems(settings.maxNoteLen)(q, OFulltext.FtsInput(ftq), settings.batch)
              .map(Items.ftsItems(false))

        case _ =>
          if (settings.resolveDetails)
            is.findItemsWithTags(settings.maxNoteLen)(q, settings.batch)
              .map(Items.itemsFull)
          else
            is.findItems(settings.maxNoteLen)(q, settings.batch)
              .map(Items.itemsPlain)
      }
  }

}
