/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.fts

import java.time.{Instant, LocalDate}

import cats.effect.IO
import cats.syntax.option._
import cats.syntax.traverse._
import fs2.Stream

import docspell.common._
import docspell.ftsclient.FtsResult
import docspell.ftsclient.FtsResult.{AttachmentData, ItemMatch}
import docspell.store._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.queries.{QItem, QLogin, Query}
import docspell.store.records.{RCollective, RItem, RUser}

import doobie._

class TempFtsOpsTest extends DatabaseTest {
  private[this] val logger = docspell.logging.getLogger[IO]

  override def munitFixtures = postgresAll ++ mariaDbAll ++ h2Memory

  def id(str: String): Ident = Ident.unsafe(str)

  def stores: (Store[IO], Store[IO], Store[IO]) =
    (pgStore(), mariaStore(), h2Store())

  test("create temporary table") {
    val (pg, maria, h2) = stores
    for {
      _ <- assertCreateTempTable(pg)
      _ <- assertCreateTempTable(maria)
      _ <- assertCreateTempTable(h2)
    } yield ()
  }

  test("query items sql") {
    val (pg, maria, h2) = stores
    for {
      _ <- prepareItems(pg)
      _ <- prepareItems(maria)
      _ <- prepareItems(h2)
      _ <- assertQueryItem(pg, ftsResults(10, 10))
//      _ <- assertQueryItem(pg, ftsResults(3000, 500))
      _ <- assertQueryItem(maria, ftsResults(10, 10))
//      _ <- assertQueryItem(maria, ftsResults(3000, 500))
      _ <- assertQueryItem(h2, ftsResults(10, 10))
//      _ <- assertQueryItem(h2, ftsResults(3000, 500))
    } yield ()
  }

  def prepareItems(store: Store[IO]) =
    for {
      cid <- store.transact(RCollective.insert(makeCollective))
      _ <- store.transact(RUser.insert(makeUser(cid)))
      items = (0 until 200)
        .map(makeItem(_, cid))
        .toList
      _ <- items.traverse(i => store.transact(RItem.insert(i)))
    } yield ()

  def assertCreateTempTable(store: Store[IO]) = {
    val insertRows =
      List(
        RFtsResult(id("abc-def"), None, None),
        RFtsResult(id("abc-123"), Some(1.56), None),
        RFtsResult(id("zyx-321"), None, None)
      )
    val create =
      for {
        table <- TempFtsOps.createTable(store.dbms, "tt")
        n <- table.insertAll(insertRows)
        _ <- table.createIndex
        rows <- Select(select(table.all), from(table))
          .orderBy(table.id)
          .build
          .query[RFtsResult]
          .to[List]
      } yield (n, rows)

    val verify =
      store.transact(create).map { case (inserted, rows) =>
        if (store.dbms != Db.MariaDB) {
          assertEquals(inserted, 3)
        }
        assertEquals(rows, insertRows.sortBy(_.id))
      }

    verify *> verify
  }

  def assertQueryItem(store: Store[IO], ftsResults: Stream[ConnectionIO, FtsResult]) =
    for {
      today <- IO(LocalDate.now())
      account <- store
        .transact(QLogin.findAccount(DocspellSystem.account))
        .map(_.get)
      tempTable = ftsResults
        .through(TempFtsOps.prepareTable(store.dbms, "fts_result"))
        .compile
        .lastOrError
      q = Query(Query.Fix(account, None, None), Query.QueryExpr(None))
      timed <- Duration.stopTime[IO]
      items <- store
        .transact(
          tempTable.flatMap(t =>
            QItem
              .queryItems(q, today, 0, Batch.limit(10), t.some)
              .compile
              .to(List)
          )
        )
      duration <- timed
      _ <- logger.info(s"Join took: ${duration.formatExact}")

    } yield {
      assert(items.nonEmpty)
      assert(items.head.context.isDefined)
    }

  def ftsResult(start: Int, end: Int): FtsResult = {
    def matchData(n: Int): List[ItemMatch] =
      List(
        ItemMatch(
          id(s"m$n"),
          id(s"item-$n"),
          CollectiveId(1),
          math.random(),
          FtsResult.ItemData
        ),
        ItemMatch(
          id(s"m$n-1"),
          id(s"item-$n"),
          CollectiveId(1),
          math.random(),
          AttachmentData(id(s"item-$n-attach-1"), "attachment.pdf")
        )
      )

    val hl =
      (start until end)
        .flatMap(n =>
          List(
            id(s"m$n-1") -> List("this *a test* please"),
            id(s"m$n") -> List("only **items** here")
          )
        )
        .toMap

    FtsResult.empty
      .copy(
        count = end,
        highlight = hl,
        results = (start until end).toList.flatMap(matchData)
      )
  }

  def ftsResults(len: Int, chunkSize: Int): Stream[ConnectionIO, FtsResult] = {
    val chunks = len / chunkSize
    Stream.range(0, chunks).map { n =>
      val start = n * chunkSize
      val end = start + chunkSize
      ftsResult(start, end)
    }
  }

  def makeUser(cid: CollectiveId): RUser =
    RUser(
      Ident.unsafe("uid1"),
      DocspellSystem.account.user,
      cid,
      Password("test"),
      UserState.Active,
      AccountSource.Local,
      None,
      0,
      None,
      Timestamp(Instant.now)
    )

  def makeCollective: RCollective =
    RCollective(
      CollectiveId.unknown,
      DocspellSystem.account.collective,
      CollectiveState.Active,
      Language.English,
      integrationEnabled = true,
      ts
    )

  def makeItem(n: Int, cid: CollectiveId): RItem =
    RItem(
      id(s"item-$n"),
      cid,
      s"item $n",
      None,
      "test",
      Direction.Incoming,
      ItemState.Created,
      None,
      None,
      None,
      None,
      None,
      ts,
      ts,
      None,
      None
    )

  val ts = Timestamp.ofMillis(1654329963743L)
}
