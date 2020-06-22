package docspell.backend.ops

import cats.effect._
import cats.implicits._
import fs2.Stream
import docspell.common._
import docspell.ftsclient._
import docspell.backend.JobFactory
import docspell.store.Store
import docspell.store.records.RJob
import docspell.store.queue.JobQueue
import OItemSearch.{Batch, ListItem, ListItemWithTags, Query}

trait OFulltext[F[_]] {

  def findItems(
      q: Query,
      fts: OFulltext.FtsInput,
      batch: Batch
  ): F[Vector[OFulltext.FtsItem]]

  /** Same as `findItems` but does more queries per item to find all tags. */
  def findItemsWithTags(
      q: Query,
      fts: OFulltext.FtsInput,
      batch: Batch
  ): F[Vector[OFulltext.FtsItemWithTags]]

  /** Clears the full-text index completely and launches a task that
    * indexes all data.
    */
  def reindexAll: F[Unit]

  /** Clears the full-text index for the given collective and starts a
    * task indexing all their data.
    */
  def reindexCollective(account: AccountId): F[Unit]
}

object OFulltext {

  case class FtsInput(
      query: String,
      highlightPre: String = "***",
      highlightPost: String = "***"
  )

  case class FtsDataItem(
      score: Double,
      matchData: FtsResult.MatchData,
      context: List[String]
  )
  case class FtsData(
      maxScore: Double,
      count: Int,
      qtime: Duration,
      items: List[FtsDataItem]
  )
  case class FtsItem(item: ListItem, ftsData: FtsData)
  case class FtsItemWithTags(item: ListItemWithTags, ftsData: FtsData)

  def apply[F[_]: Effect](
      itemSearch: OItemSearch[F],
      fts: FtsClient[F],
      store: Store[F],
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OFulltext[F]] =
    Resource.pure[F, OFulltext[F]](new OFulltext[F] {
      def reindexAll: F[Unit] =
        for {
          job <- JobFactory.reIndexAll[F]
          _   <- queue.insertIfNew(job) *> joex.notifyAllNodes
        } yield ()

      def reindexCollective(account: AccountId): F[Unit] =
        for {
          exist <- store.transact(
            RJob.findNonFinalByTracker(DocspellSystem.migrationTaskTracker)
          )
          job <- JobFactory.reIndex(account)
          _ <-
            if (exist.isDefined) ().pure[F]
            else queue.insertIfNew(job) *> joex.notifyAllNodes
        } yield ()

      def findItems(q: Query, ftsQ: FtsInput, batch: Batch): F[Vector[FtsItem]] =
        findItemsFts(q, ftsQ, batch.first, itemSearch.findItems, convertFtsData[ListItem])
          .drop(batch.offset.toLong)
          .take(batch.limit.toLong)
          .map({ case (li, fd) => FtsItem(li, fd) })
          .compile
          .toVector

      def findItemsWithTags(
          q: Query,
          ftsQ: FtsInput,
          batch: Batch
      ): F[Vector[FtsItemWithTags]] =
        findItemsFts(
          q,
          ftsQ,
          batch.first,
          itemSearch.findItemsWithTags,
          convertFtsData[ListItemWithTags]
        )
          .drop(batch.offset.toLong)
          .take(batch.limit.toLong)
          .map({ case (li, fd) => FtsItemWithTags(li, fd) })
          .compile
          .toVector

      private def findItemsFts[A: ItemId, B](
          q: Query,
          ftsQ: FtsInput,
          batch: Batch,
          search: (Query, Batch) => F[Vector[A]],
          convert: (
              FtsResult,
              Map[Ident, List[FtsResult.ItemMatch]]
          ) => PartialFunction[A, (A, FtsData)]
      ): Stream[F, (A, FtsData)] = {

        val sqlResult = search(q, batch)
        val fq = FtsQuery(
          ftsQ.query,
          q.collective,
          Set.empty,
          batch.limit,
          batch.offset,
          FtsQuery.HighlightSetting(ftsQ.highlightPre, ftsQ.highlightPost)
        )

        val qres =
          for {
            items <- sqlResult
            ids  = items.map(a => ItemId[A].itemId(a))
            ftsQ = fq.copy(items = ids.toSet)
            ftsR <- fts.search(ftsQ)
            ftsItems = ftsR.results.groupBy(_.itemId)
            res      = items.collect(convert(ftsR, ftsItems))
          } yield res

        Stream.eval(qres).flatMap { v =>
          val results = Stream.emits(v)
          if (v.size < batch.limit) results
          else results ++ findItemsFts(q, ftsQ, batch.next, search, convert)
        }
      }

      private def convertFtsData[A: ItemId](
          ftr: FtsResult,
          ftrItems: Map[Ident, List[FtsResult.ItemMatch]]
      ): PartialFunction[A, (A, FtsData)] = {
        case a if ftrItems.contains(ItemId[A].itemId(a)) =>
          val ftsDataItems = ftrItems
            .get(ItemId[A].itemId(a))
            .getOrElse(Nil)
            .map(im =>
              FtsDataItem(im.score, im.data, ftr.highlight.get(im.id).getOrElse(Nil))
            )
          (a, FtsData(ftr.maxScore, ftr.count, ftr.qtime, ftsDataItems))
      }
    })

  trait ItemId[A] {
    def itemId(a: A): Ident
  }
  object ItemId {
    def apply[A](implicit ev: ItemId[A]): ItemId[A] = ev

    def from[A](f: A => Ident): ItemId[A] =
      new ItemId[A] {
        def itemId(a: A) = f(a)
      }

    implicit val listItemId: ItemId[ListItem] =
      ItemId.from(_.id)

    implicit val listItemWithTagsId: ItemId[ListItemWithTags] =
      ItemId.from(_.item.id)
  }
}
