package docspell.backend.ops

import cats.effect._
import cats.implicits._
import fs2.Stream
import docspell.ftsclient._
import OItemSearch.{Batch, ListItem, ListItemWithTags, Query}

trait OFulltext[F[_]] {

  def findItems(q: Query, fts: String, batch: Batch): F[Vector[ListItem]]

  /** Same as `findItems` but does more queries per item to find all tags. */
  def findItemsWithTags(q: Query, fts: String, batch: Batch): F[Vector[ListItemWithTags]]

}

object OFulltext {
  // maybe use a temporary table? could run fts and do .take(batch.limit) and store this in sql
  // then run a query
  // check if supported by mariadb, postgres and h2. seems like it is supported everywhere

  def apply[F[_]: Effect](
      itemSearch: OItemSearch[F],
      fts: FtsClient[F]
  ): Resource[F, OFulltext[F]] =
    Resource.pure[F, OFulltext[F]](new OFulltext[F] {

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
        val fq = FtsQuery(ftsQ, q.collective, batch.limit, batch.offset, Nil)

        val qres =
          for {
            items <-
              fts
                .searchBasic(fq)
                .flatMap(r => Stream.emits(r.results))
                .map(_.itemId)
                .compile
                .toVector
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
