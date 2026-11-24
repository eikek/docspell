/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftsclient

import cats.effect._

import docspell.common._

import munit.CatsEffectSuite

class FtsClientSearchMaxTest extends CatsEffectSuite {

  test("searchMax stops after maxResults even when more pages exist") {
    val totalHits = 2500
    val pageSize = 500
    val maxResults = 50

    for {
      calls <- Ref.of[IO, Int](0)
      client = countingClient(calls, totalHits)
      q = FtsQuery("invoice", CollectiveId(1), pageSize, 0)
      pages <- client.searchMax(q, maxResults).compile.toList
      n <- calls.get
    } yield {
      assertEquals(pages.map(_.results.size).sum, maxResults)
      assertEquals(n, 1)
      assertEquals(pages.head.results.size, maxResults)
    }
  }

  test("searchMax pages until maxResults across multiple chunks") {
    val totalHits = 2500
    val pageSize = 500
    val maxResults = 1200

    for {
      calls <- Ref.of[IO, Int](0)
      client = countingClient(calls, totalHits)
      q = FtsQuery("invoice", CollectiveId(1), pageSize, 0)
      pages <- client.searchMax(q, maxResults).compile.toList
      n <- calls.get
    } yield {
      assertEquals(pages.map(_.results.size).sum, maxResults)
      assertEquals(n, 3) // 500 + 500 + 200
      assertEquals(pages.last.results.size, 200)
    }
  }

  test("searchAll still exhausts all pages") {
    val totalHits = 1200
    val pageSize = 500

    for {
      calls <- Ref.of[IO, Int](0)
      client = countingClient(calls, totalHits)
      q = FtsQuery("invoice", CollectiveId(1), pageSize, 0)
      pages <- client.searchAll(q).compile.toList
      n <- calls.get
    } yield {
      assertEquals(pages.map(_.results.size).sum, totalHits)
      assertEquals(n, 3)
    }
  }

  private def countingClient(calls: Ref[IO, Int], totalHits: Int): FtsClient[IO] =
    new FtsClient[IO] {
      def initialize: IO[List[FtsMigration[IO]]] = IO.pure(Nil)
      def initializeNew: List[FtsMigration[IO]] = Nil
      def indexData(
          logger: docspell.logging.Logger[IO],
          data: fs2.Stream[IO, TextData]
      ): IO[Unit] = IO.unit
      def updateIndex(
          logger: docspell.logging.Logger[IO],
          data: fs2.Stream[IO, TextData]
      ): IO[Unit] = IO.unit
      def updateFolder(
          logger: docspell.logging.Logger[IO],
          itemId: Ident,
          collective: CollectiveId,
          folder: Option[Ident]
      ): IO[Unit] = IO.unit
      def removeItem(logger: docspell.logging.Logger[IO], itemId: Ident): IO[Unit] =
        IO.unit
      def removeAttachment(
          logger: docspell.logging.Logger[IO],
          attachId: Ident
      ): IO[Unit] = IO.unit
      def clearAll(logger: docspell.logging.Logger[IO]): IO[Unit] = IO.unit
      def clear(logger: docspell.logging.Logger[IO], collective: CollectiveId): IO[Unit] =
        IO.unit

      def search(q: FtsQuery): IO[FtsResult] =
        calls.update(_ + 1).as {
          val start = q.offset
          val end = math.min(totalHits, q.offset + q.limit)
          val matches =
            (start until end).toList.map { i =>
              FtsResult.ItemMatch(
                Ident.unsafe(s"m$i"),
                Ident.unsafe(s"item-$i"),
                CollectiveId(1),
                1.0,
                FtsResult.ItemData
              )
            }
          FtsResult(
            Duration.millis(1),
            totalHits,
            1.0,
            Map.empty,
            matches
          )
        }
    }
}
