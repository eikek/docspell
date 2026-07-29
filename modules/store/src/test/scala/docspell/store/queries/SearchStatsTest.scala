/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import java.time.{Instant, LocalDate}

import cats.effect.IO
import cats.syntax.traverse._

import docspell.common._
import docspell.store._
import docspell.store.records._

class SearchStatsTest extends DatabaseTest {

  override def munitFixtures = h2Memory

  // H2 covers profile logic only; PostgreSQL/MariaDB planner behavior for
  // literal item_id filters is not exercised in CI.

  test("searchStats profiles omit heavy aggregates as expected") {
    val store = h2Store()
    for {
      cid <- prepareItems(store)
      _ <- prepareCustomFields(store, cid, Ident.unsafe("item-0"))
      today <- IO(LocalDate.now())
      account <- store
        .transact(QLogin.findAccount(DocspellSystem.account))
        .map(_.get)
      q = Query(Query.Fix(account, None, None), Query.QueryExpr(None))
      full <- store.transact(QItem.searchStats(today, None)(q))
      general <- store.transact(QItem.searchStatsGeneral(today, None)(q))
      fields <- store.transact(QItem.searchStatsFields(today, None)(q))
    } yield {
      assertEquals(general.fields, Nil)
      assertEquals(general.folders, Nil)
      assertEquals(general.corrOrgs, Nil)
      assert(general.fieldCount.isDefined)
      assertEquals(general.fieldCount.get, 1)
      assert(general.orgCount.isDefined)
      assert(general.personCount.isDefined)
      assert(general.equipCount.isDefined)
      assertEquals(general.count, 5)

      assertEquals(fields.tags, Nil)
      assertEquals(fields.folders, Nil)
      assertEquals(fields.count, 5)
      assert(fields.fieldCount.isEmpty)
      assertEquals(fields.fields.length, 2)
      assert(fields.fields.exists(_.field.ftype == CustomFieldType.money))

      assert(full.fields.length >= 2)
      assert(full.count >= 5)
      assert(general.count == full.count)
    }
  }

  private def prepareItems(store: Store[IO]): IO[CollectiveId] =
    for {
      cid <- store.transact(RCollective.insert(makeCollective))
      _ <- store.transact(RUser.insert(makeUser(cid)))
      items = (0 until 5).map(makeItem(_, cid)).toList
      _ <- items.traverse(i => store.transact(RItem.insert(i)))
    } yield cid

  private def prepareCustomFields(store: Store[IO], cid: CollectiveId, itemId: Ident) = {
    val textField = RCustomField(
      Ident.unsafe("cf-text"),
      Ident.unsafe("notes"),
      Some("Notes"),
      cid,
      CustomFieldType.text,
      ts
    )
    val moneyField = RCustomField(
      Ident.unsafe("cf-money"),
      Ident.unsafe("amount"),
      Some("Amount"),
      cid,
      CustomFieldType.money,
      ts
    )
    store.transact(
      for {
        _ <- RCustomField.insert(textField)
        _ <- RCustomField.insert(moneyField)
        _ <- RCustomFieldValue.insert(
          RCustomFieldValue(
            Ident.unsafe("cv-text"),
            itemId,
            textField.id,
            "hello"
          )
        )
        _ <- RCustomFieldValue.insert(
          RCustomFieldValue(
            Ident.unsafe("cv-money"),
            itemId,
            moneyField.id,
            "10.50"
          )
        )
      } yield ()
    )
  }

  private def makeUser(cid: CollectiveId): RUser =
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

  private def makeCollective: RCollective =
    RCollective(
      CollectiveId.unknown,
      DocspellSystem.account.collective,
      CollectiveState.Active,
      Language.English,
      integrationEnabled = true,
      ts
    )

  private def makeItem(n: Int, cid: CollectiveId): RItem =
    RItem(
      Ident.unsafe(s"item-$n"),
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

  private val ts = Timestamp.ofMillis(1654329963743L)
}
