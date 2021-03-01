package docspell.backend.ops

import cats.effect.Sync
import cats.implicits._

import docspell.backend.ops.OSimpleSearch._
import docspell.common._
import docspell.query.{ItemQueryParser, ParseFailure}
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
  )(fix: Query.Fix, q: ItemQueryString): Either[ParseFailure, F[Items]]
  def searchSummaryByString(
      useFTS: Boolean
  )(fix: Query.Fix, q: ItemQueryString): Either[ParseFailure, F[SearchSummary]]

}

object OSimpleSearch {

  final case class Settings(
      batch: Batch,
      useFTS: Boolean,
      resolveDetails: Boolean,
      maxNoteLen: Int
  )

  sealed trait Items {
    def fold[A](
        f1: Vector[OFulltext.FtsItem] => A,
        f2: Vector[OFulltext.FtsItemWithTags] => A,
        f3: Vector[OItemSearch.ListItem] => A,
        f4: Vector[OItemSearch.ListItemWithTags] => A
    ): A

  }
  object Items {
    def ftsItems(items: Vector[OFulltext.FtsItem]): Items =
      FtsItems(items)

    case class FtsItems(items: Vector[OFulltext.FtsItem]) extends Items {
      def fold[A](
          f1: Vector[OFulltext.FtsItem] => A,
          f2: Vector[OFulltext.FtsItemWithTags] => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f1(items)

    }

    def ftsItemsFull(items: Vector[OFulltext.FtsItemWithTags]): Items =
      FtsItemsFull(items)

    case class FtsItemsFull(items: Vector[OFulltext.FtsItemWithTags]) extends Items {
      def fold[A](
          f1: Vector[OFulltext.FtsItem] => A,
          f2: Vector[OFulltext.FtsItemWithTags] => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f2(items)
    }

    def itemsPlain(items: Vector[OItemSearch.ListItem]): Items =
      ItemsPlain(items)

    case class ItemsPlain(items: Vector[OItemSearch.ListItem]) extends Items {
      def fold[A](
          f1: Vector[OFulltext.FtsItem] => A,
          f2: Vector[OFulltext.FtsItemWithTags] => A,
          f3: Vector[OItemSearch.ListItem] => A,
          f4: Vector[OItemSearch.ListItemWithTags] => A
      ): A = f3(items)
    }

    def itemsFull(items: Vector[OItemSearch.ListItemWithTags]): Items =
      ItemsFull(items)

    case class ItemsFull(items: Vector[OItemSearch.ListItemWithTags]) extends Items {
      def fold[A](
          f1: Vector[OFulltext.FtsItem] => A,
          f2: Vector[OFulltext.FtsItemWithTags] => A,
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
    )(fix: Query.Fix, q: ItemQueryString): Either[ParseFailure, F[Items]] =
      ItemQueryParser
        .parse(q.query)
        .map(iq => Query(fix, Query.QueryExpr(iq)))
        .map(search(settings)(_, None)) //TODO resolve content:xyz expressions

    def searchSummaryByString(
        useFTS: Boolean
    )(fix: Query.Fix, q: ItemQueryString): Either[ParseFailure, F[SearchSummary]] =
      ItemQueryParser
        .parse(q.query)
        .map(iq => Query(fix, Query.QueryExpr(iq)))
        .map(searchSummary(useFTS)(_, None)) //TODO resolve content:xyz expressions

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
              .map(Items.ftsItemsFull)
          else if (settings.resolveDetails)
            fts
              .findItemsWithTags(settings.maxNoteLen)(
                q,
                OFulltext.FtsInput(ftq),
                settings.batch
              )
              .map(Items.ftsItemsFull)
          else
            fts
              .findItems(settings.maxNoteLen)(q, OFulltext.FtsInput(ftq), settings.batch)
              .map(Items.ftsItems)

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
