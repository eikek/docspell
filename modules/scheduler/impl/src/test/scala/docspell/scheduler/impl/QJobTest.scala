/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import java.time.Instant
import java.util.concurrent.atomic.AtomicLong

import cats.syntax.all._

import docspell.common._
import docspell.store.qb.{Condition, DML}
import docspell.store.records.{RJob, RJobGroupUse}
import docspell.store.{DatabaseTest, Db}

class QJobTest extends DatabaseTest {
  private[this] val c = new AtomicLong(0)

  private val worker = Ident.unsafe("joex1")
  private val initialPause = Duration.seconds(5)
  private val nowTs = Timestamp(Instant.parse("2021-06-26T14:54:00Z"))
  private val group1 = Ident.unsafe("group1")
  private val group2 = Ident.unsafe("group2")

  override def munitFixtures = h2File ++ mariaDbAll ++ postgresAll

  def createStore(dbms: Db) =
    dbms.fold(pgStore(), mariaStore(), h2FileStore())

  def createJob(group: Ident): RJob =
    RJob.fromJson[Unit](
      Ident.unsafe(s"job-${c.incrementAndGet()}"),
      Ident.unsafe("task"),
      group,
      (),
      "some subject",
      nowTs - Duration.days(3),
      Ident.unsafe("user1"),
      Priority.Low,
      None
    )

  Db.all.toList.foreach { db =>
    test(s"selectNextGroup on empty table ($db)") {
      val store = createStore(db)
      val nextGroup = for {
        _ <- store.transact(RJobGroupUse.deleteAll)
        _ <- store.transact(DML.delete(RJob.T, Condition.unit))
        next <- store.transact(QJob.selectNextGroup(worker, nowTs, initialPause))
      } yield next

      nextGroup.assertEquals(None)
    }
  }

  Db.all.toList.foreach { db =>
    test(s"set group must insert or update ($db)") {
      val store = createStore(db)
      val res =
        for {
          _ <- store.transact(RJobGroupUse.setGroup(RJobGroupUse(group1, worker)))
          res <- store.transact(RJobGroupUse.findGroup(worker))
        } yield res

      res.assertEquals(Some(group1))
    }
  }

  Db.all.toList.foreach { db =>
    test(s"selectNextGroup should return first group on initial state ($db)") {
      val store = createStore(db)
      val nextGroup = for {
        _ <- List(group1, group2, group1, group2, group2)
          .map(createJob)
          .map(RJob.insert)
          .traverse_(store.transact(_))
        _ <- store.transact(RJobGroupUse.deleteAll)
        next <- store.transact(QJob.selectNextGroup(worker, nowTs, initialPause))
      } yield next

      nextGroup.assertEquals(Some(group1))
    }
  }

  Db.all.toList.foreach { db =>
    test(s"selectNextGroup should return second group on subsequent call ($db)") {
      val store = createStore(db)
      val nextGroup = for {
        _ <- List(group1, group2, group1, group2)
          .map(createJob)
          .map(RJob.insert)
          .traverse_(store.transact(_))
        _ <- store.transact(RJobGroupUse.deleteAll)
        _ <- store.transact(RJobGroupUse.setGroup(RJobGroupUse(group1, worker)))
        next <- store.transact(QJob.selectNextGroup(worker, nowTs, initialPause))
      } yield next

      nextGroup.assertEquals(Some(group2))
    }
  }

  Db.all.toList.foreach { db =>
    test(s"selectNextGroup should return first group on subsequent call ($db)") {
      val store = createStore(db)
      val nextGroup = for {
        _ <- List(group1, group2, group1, group2)
          .map(createJob)
          .map(RJob.insert)
          .traverse_(store.transact(_))
        _ <- store.transact(RJobGroupUse.deleteAll)
        _ <- store.transact(RJobGroupUse.setGroup(RJobGroupUse(group2, worker)))
        next <- store.transact(QJob.selectNextGroup(worker, nowTs, initialPause))
      } yield next

      nextGroup.assertEquals(Some(group1))
    }
  }
}
