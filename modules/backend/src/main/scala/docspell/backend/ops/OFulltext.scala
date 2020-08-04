package docspell.backend.ops

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.JobFactory
import docspell.backend.ops.OItemSearch._
import docspell.common._
import docspell.ftsclient._
import docspell.store.Store
import docspell.store.queries.{QFolder, QItem}
import docspell.store.queue.JobQueue
import docspell.store.records.RJob

trait OFulltext[F[_]] {

  def findItems(maxNoteLen: Int)(
      q: Query,
      fts: OFulltext.FtsInput,
      batch: Batch
  ): F[Vector[OFulltext.FtsItem]]

  /** Same as `findItems` but does more queries per item to find all tags. */
  def findItemsWithTags(maxNoteLen: Int)(
      q: Query,
      fts: OFulltext.FtsInput,
      batch: Batch
  ): F[Vector[OFulltext.FtsItemWithTags]]

  def findIndexOnly(maxNoteLen: Int)(
      fts: OFulltext.FtsInput,
      account: AccountId,
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

      def findIndexOnly(maxNoteLen: Int)(
          ftsQ: OFulltext.FtsInput,
          account: AccountId,
          batch: Batch
      ): F[Vector[OFulltext.FtsItemWithTags]] = {
        val fq = FtsQuery(
          ftsQ.query,
          account.collective,
          Set.empty,
          Set.empty,
          batch.limit,
          batch.offset,
          FtsQuery.HighlightSetting(ftsQ.highlightPre, ftsQ.highlightPost)
        )
        for {
          folders <- store.transact(QFolder.getMemberFolders(account))
          ftsR    <- fts.search(fq.withFolders(folders))
          ftsItems = ftsR.results.groupBy(_.itemId)
          select =
            ftsItems.values
              .map(_.sortBy(-_.score).head)
              .map(r => QItem.SelectedItem(r.itemId, r.score))
              .toSet
          itemsWithTags <-
            store
              .transact(
                QItem.findItemsWithTags(
                  account.collective,
                  QItem.findSelectedItems(QItem.Query.empty(account), maxNoteLen, select)
                )
              )
              .take(batch.limit.toLong)
              .compile
              .toVector
          res =
            itemsWithTags
              .collect(convertFtsData(ftsR, ftsItems))
              .map({ case (li, fd) => FtsItemWithTags(li, fd) })
        } yield res
      }

      def findItems(
          maxNoteLen: Int
      )(q: Query, ftsQ: FtsInput, batch: Batch): F[Vector[FtsItem]] =
        findItemsFts(
          q,
          ftsQ,
          batch.first,
          itemSearch.findItems(maxNoteLen),
          convertFtsData[ListItem]
        )
          .drop(batch.offset.toLong)
          .take(batch.limit.toLong)
          .map({ case (li, fd) => FtsItem(li, fd) })
          .compile
          .toVector

      def findItemsWithTags(maxNoteLen: Int)(
          q: Query,
          ftsQ: FtsInput,
          batch: Batch
      ): F[Vector[FtsItemWithTags]] =
        findItemsFts(
          q,
          ftsQ,
          batch.first,
          itemSearch.findItemsWithTags(maxNoteLen),
          convertFtsData[ListItemWithTags]
        )
          .drop(batch.offset.toLong)
          .take(batch.limit.toLong)
          .map({ case (li, fd) => FtsItemWithTags(li, fd) })
          .compile
          .toVector

      // Helper

      private def findItemsFts[A: ItemId, B](
          q: Query,
          ftsQ: FtsInput,
          batch: Batch,
          search: (Query, Batch) => F[Vector[A]],
          convert: (
              FtsResult,
              Map[Ident, List[FtsResult.ItemMatch]]
          ) => PartialFunction[A, (A, FtsData)]
      ): Stream[F, (A, FtsData)] =
        findItemsFts0(q, ftsQ, batch, search, convert)
          .takeThrough(_._1 >= batch.limit)
          .flatMap(x => Stream.emits(x._2))

      private def findItemsFts0[A: ItemId, B](
          q: Query,
          ftsQ: FtsInput,
          batch: Batch,
          search: (Query, Batch) => F[Vector[A]],
          convert: (
              FtsResult,
              Map[Ident, List[FtsResult.ItemMatch]]
          ) => PartialFunction[A, (A, FtsData)]
      ): Stream[F, (Int, Vector[(A, FtsData)])] = {
        val sqlResult = search(q, batch)
        val fq = FtsQuery(
          ftsQ.query,
          q.account.collective,
          Set.empty,
          Set.empty,
          0,
          0,
          FtsQuery.HighlightSetting(ftsQ.highlightPre, ftsQ.highlightPost)
        )

        val qres =
          for {
            items <- sqlResult
            ids = items.map(a => ItemId[A].itemId(a))
            // must find all index results involving the items.
            // Currently there is one result per item + one result per
            // attachment
            limit = items.map(a => ItemId[A].fileCount(a)).sum + items.size
            ftsQ  = fq.copy(items = ids.toSet, limit = limit)
            ftsR <- fts.search(ftsQ)
            ftsItems = ftsR.results.groupBy(_.itemId)
            res      = items.collect(convert(ftsR, ftsItems))
          } yield (items.size, res)

        Stream.eval(qres) ++ findItemsFts0(q, ftsQ, batch.next, search, convert)
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

    def fileCount(a: A): Int
  }
  object ItemId {
    def apply[A](implicit ev: ItemId[A]): ItemId[A] = ev

    def from[A](f: A => Ident, g: A => Int): ItemId[A] =
      new ItemId[A] {
        def itemId(a: A)    = f(a)
        def fileCount(a: A) = g(a)
      }

    implicit val listItemId: ItemId[ListItem] =
      ItemId.from(_.id, _.fileCount)

    implicit val listItemWithTagsId: ItemId[ListItemWithTags] =
      ItemId.from(_.item.id, _.item.fileCount)
  }
}
