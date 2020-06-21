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

  def findItems(q: Query, fts: String, batch: Batch): F[Vector[ListItem]]

  /** Same as `findItems` but does more queries per item to find all tags. */
  def findItemsWithTags(q: Query, fts: String, batch: Batch): F[Vector[ListItemWithTags]]

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
  // maybe use a temporary table? could run fts and do .take(batch.limit) and store this in sql
  // then run a query
  // check if supported by mariadb, postgres and h2. seems like it is supported everywhere

  def apply[F[_]: Effect](
      itemSearch: OItemSearch[F],
      fts: FtsClient[F],
      store: Store[F],
      queue: JobQueue[F]
  ): Resource[F, OFulltext[F]] =
    Resource.pure[F, OFulltext[F]](new OFulltext[F] {
      def reindexAll: F[Unit] =
        for {
          job <- JobFactory.reIndexAll[F]
          _   <- queue.insertIfNew(job)
        } yield ()

      def reindexCollective(account: AccountId): F[Unit] =
        for {
          exist <- store.transact(
            RJob.findNonFinalByTracker(DocspellSystem.migrationTaskTracker)
          )
          job <- JobFactory.reIndex(account)
          _ <-
            if (exist.isDefined) ().pure[F]
            else queue.insertIfNew(job)
        } yield ()

      def findItems(q: Query, ftsQ: String, batch: Batch): F[Vector[ListItem]] =
        findItemsFts(q, ftsQ, batch, itemSearch.findItems)
          .take(batch.limit.toLong)
          .compile
          .toVector

      def findItemsWithTags(
          q: Query,
          ftsQ: String,
          batch: Batch
      ): F[Vector[ListItemWithTags]] =
        findItemsFts(q, ftsQ, batch, itemSearch.findItemsWithTags)
          .take(batch.limit.toLong)
          .compile
          .toVector

      private def findItemsFts[A](
          q: Query,
          ftsQ: String,
          batch: Batch,
          search: (Query, Batch) => F[Vector[A]]
      ): Stream[F, A] = {
        val fq = FtsQuery(ftsQ, q.collective, Nil, batch.limit, batch.offset)

        val qres =
          for {
            items <-
              fts
                .search(fq)
                .map(_.results.map(_.itemId))
                .map(_.toSet)
            sq = q.copy(itemIds = Some(items))
            res <- search(sq, batch)
          } yield res

        Stream.eval(qres).flatMap { v =>
          val results = Stream.emits(v)
          if (v.size < batch.limit) results
          else results ++ findItemsFts(q, ftsQ, batch.next, search)
        }
      }

    })
}
